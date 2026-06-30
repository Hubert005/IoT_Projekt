import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../models/generated_cocktail.dart';
import '../models/pump_setup.dart';
import 'gemma_recipe_parsing.dart';
import 'recipe_generator_service.dart';

class GemmaRecipeGeneratorService implements RecipeGeneratorService {
  GemmaRecipeGeneratorService({
    RecipeGeneratorService? fallback,
    this.modelUrl = _defaultModelUrl,
    this.assetPath,
    this.huggingFaceToken,
    this.maxTokens = 2048,
    this.generateTimeout = const Duration(seconds: 120),
  }) : _fallback = fallback ?? const MockRecipeGeneratorService();

  static const String _defaultModelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task';

  final RecipeGeneratorService _fallback;
  final String modelUrl;
  final String? assetPath;
  final String? huggingFaceToken;
  final int maxTokens;
  final Duration generateTimeout;
  final ValueNotifier<GemmaModelStatus> status =
      ValueNotifier(const GemmaModelStatus.idle());

  Future<bool>? _readyFuture;
  InferenceModel? _model;

  Future<bool> _ensureReady() => _readyFuture ??= _initModel();

  Future<bool> _initModel() async {
    try {
      status.value = const GemmaModelStatus.loading();
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
      if (cocktails.length < 3) return _fallback.generate(setup);
      return cocktails;
    } catch (e) {
      debugPrint('GemmaRecipeGeneratorService generate failed: $e');
      return _fallback.generate(setup);
    }
  }
  String _responseText(ModelResponse response) {
    return switch (response) {
      TextResponse(:final token) => token,
      ThinkingResponse(:final content) => content,
      _ => response.toString(),
    };
  }

  int _asPercent(dynamic progress) {
    if (progress is num) {
      final v = progress <= 1 ? progress * 100 : progress;
      return v.round().clamp(0, 100);
    }
    return 0;
  }

  void dispose() => status.dispose();
}
