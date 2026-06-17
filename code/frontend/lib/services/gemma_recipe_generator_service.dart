import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../models/generated_cocktail.dart';
import '../models/pump_setup.dart';
import 'gemma_recipe_parsing.dart';
import 'recipe_generator_service.dart';

/// On-device LLM cocktail generator backed by [flutter_gemma]. Runs a small
/// Gemma model entirely on the phone — no API key, no network cost at runtime
/// (only a one-time model download).
///
/// Designed to never hard-fail: if the model can't be downloaded/loaded, the
/// platform is unsupported, or generation/parsing fails, it transparently falls
/// back to [MockRecipeGeneratorService]. This keeps the recipe flow (and test
/// mode) working everywhere. The Gemma service is only wired in `main.dart`, so
/// unit/widget tests stay on the mock and never trigger a download.
class GemmaRecipeGeneratorService implements RecipeGeneratorService {
  GemmaRecipeGeneratorService({
    RecipeGeneratorService? fallback,
    this.modelUrl = _defaultModelUrl,
    this.assetPath,
    this.huggingFaceToken,
    this.maxTokens = 2048,
    this.generateTimeout = const Duration(seconds: 120),
  }) : _fallback = fallback ?? const MockRecipeGeneratorService();

  /// Gemma 3 1B IT, 4-bit (~0.5 GB). NOTE: this repo is *gated* on Hugging Face
  /// — a direct download returns 401 without a token. To honour "no API key",
  /// either:
  ///   • set [assetPath] and bundle the .task in assets/ (fully offline), or
  ///   • point [modelUrl] at your own public (non-gated) mirror of the file, or
  ///   • pass a free [huggingFaceToken] after accepting the Gemma licence.
  /// If none works, the service simply falls back to the mock generator.
  static const String _defaultModelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task';

  final RecipeGeneratorService _fallback;

  /// Network source for the model (used when [assetPath] is null).
  final String modelUrl;

  /// Bundled-asset source (e.g. 'assets/models/gemma.task'). When set, the model
  /// is loaded from the app bundle instead of the network — no token, offline.
  final String? assetPath;

  /// Optional free Hugging Face token for downloading a gated model.
  final String? huggingFaceToken;

  final int maxTokens;
  final Duration generateTimeout;

  /// Model lifecycle for the UI (download progress, errors).
  final ValueNotifier<GemmaModelStatus> status =
      ValueNotifier(const GemmaModelStatus.idle());

  Future<bool>? _readyFuture;
  InferenceModel? _model;

  Future<bool> _ensureReady() => _readyFuture ??= _initModel();

  Future<bool> _initModel() async {
    try {
      status.value = const GemmaModelStatus.loading();
      // 0.16.x picks the inference engine automatically.
      await FlutterGemma.initialize(huggingFaceToken: huggingFaceToken);
      final builder = FlutterGemma.installModel(modelType: ModelType.gemmaIt);
      final asset = assetPath;
      if (asset != null) {
        await builder.fromAsset(asset).install();
      } else {
        await builder
            .fromNetwork(modelUrl, token: huggingFaceToken)
            .withProgress(
              (p) => status.value = GemmaModelStatus.downloading(_asPercent(p)),
            )
            .install();
      }
      _model = await FlutterGemma.getActiveModel(
        maxTokens: maxTokens,
        preferredBackend: PreferredBackend.gpu,
      );
      status.value = const GemmaModelStatus.ready();
      return true;
    } catch (e) {
      debugPrint('GemmaRecipeGeneratorService init failed: $e');
      status.value = GemmaModelStatus.unavailable('$e');
      _readyFuture = null; // allow a retry on the next generate() call
      return false;
    }
  }

  @override
  Future<List<GeneratedCocktail>> generate(PumpSetup setup) async {
    bool ready;
    try {
      ready = await _ensureReady();
    } catch (_) {
      ready = false;
    }
    final model = _model;
    if (!ready || model == null) return _fallback.generate(setup);

    try {
      final chat = await model.createChat(
        systemInstruction: kRecipeSystemInstruction,
      );
      await chat.addQueryChunk(
        Message.text(text: buildRecipePrompt(setup), isUser: true),
      );
      final response =
          await chat.generateChatResponse().timeout(generateTimeout);
      final cocktails = parseGemmaCocktails(_responseText(response), setup);
      // Too few usable cocktails — fall back rather than show a thin list.
      if (cocktails.length < 3) return _fallback.generate(setup);
      return cocktails;
    } catch (e) {
      debugPrint('GemmaRecipeGeneratorService generate failed: $e');
      return _fallback.generate(setup);
    }
  }

  /// The non-streaming response carries the full text on [TextResponse.token].
  String _responseText(ModelResponse response) {
    return switch (response) {
      TextResponse(:final token) => token,
      ThinkingResponse(:final content) => content,
      _ => response.toString(),
    };
  }

  int _asPercent(dynamic progress) {
    if (progress is num) {
      // Accept either 0..1 fractions or 0..100 percentages.
      final v = progress <= 1 ? progress * 100 : progress;
      return v.round().clamp(0, 100);
    }
    return 0;
  }

  void dispose() => status.dispose();
}
