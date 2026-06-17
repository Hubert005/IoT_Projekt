import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/generated_cocktail.dart';
import '../models/pump_setup.dart';
import 'gemma_recipe_parsing.dart';
import 'recipe_generator_service.dart';

/// Single source of truth for the current pump assignment and the cocktails
/// generated from it. Consumed by the Recipe tab (UI) and the game's
/// [DrinkService] (loser selection).
///
/// Persisted via shared_preferences so the setup and pool survive an app
/// restart. The pool is invalidated only when the pump assignment changes.
class RecipeStore extends ChangeNotifier {
  RecipeStore._({RecipeGeneratorService? generator})
      : _generator = generator ?? const MockRecipeGeneratorService();

  static final RecipeStore instance = RecipeStore._();

  /// Creates an isolated instance (not the singleton) for tests, so a fake or
  /// fast generator can be injected.
  @visibleForTesting
  RecipeStore.forTesting({RecipeGeneratorService? generator})
      : _generator = generator ?? const MockRecipeGeneratorService(delay: Duration.zero);

  static const String _setupKey = 'recipe_pump_setup';
  static const String _poolKey = 'recipe_pool';

  RecipeGeneratorService _generator;
  ValueListenable<GemmaModelStatus>? _modelStatus;

  PumpSetup _setup = PumpSetup.empty();
  List<GeneratedCocktail> _pool = const [];
  bool _generating = false;
  bool _loaded = false;

  PumpSetup get setup => _setup;
  List<GeneratedCocktail> get pool => List.unmodifiable(_pool);
  bool get isGenerating => _generating;
  bool get hasPool => _pool.isNotEmpty;

  /// On-device model status, if a model-backed generator is wired in (only in
  /// the real app via `main.dart`). Null when running on the mock generator.
  ValueListenable<GemmaModelStatus>? get modelStatus => _modelStatus;

  /// Swap the generator at app startup (e.g. an on-device LLM). The mock stays
  /// the default everywhere else, so test mode and tests never need a model.
  void useGenerator(
    RecipeGeneratorService generator, {
    ValueListenable<GemmaModelStatus>? modelStatus,
  }) {
    _generator = generator;
    _modelStatus = modelStatus;
  }

  /// Load persisted setup + pool. Safe to call multiple times.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final setupRaw = prefs.getString(_setupKey);
      if (setupRaw != null) {
        _setup = PumpSetup.fromJson(jsonDecode(setupRaw) as Map<String, dynamic>);
      }
      final poolRaw = prefs.getString(_poolKey);
      if (poolRaw != null) {
        final list = jsonDecode(poolRaw) as List;
        _pool = list
            .map((e) => GeneratedCocktail.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('RecipeStore.load failed: $e');
    }
    notifyListeners();
  }

  /// Apply a new pump assignment. If it actually changed (or no pool exists
  /// yet), the old pool is discarded and a fresh one is generated.
  Future<void> updateSetupAndRegenerate(PumpSetup newSetup) async {
    final unchanged = newSetup.sameAs(_setup) && _pool.isNotEmpty;
    _setup = newSetup;
    if (unchanged) {
      await _persist();
      notifyListeners();
      return;
    }
    await _regenerate();
  }

  /// Re-run generation for the current setup (e.g. a "regenerate" button).
  Future<void> regenerate() => _regenerate();

  Future<void> _regenerate() async {
    if (!_setup.isComplete) {
      _pool = const [];
      await _persist();
      notifyListeners();
      return;
    }
    _generating = true;
    notifyListeners();
    try {
      _pool = await _generator.generate(_setup);
    } catch (e) {
      debugPrint('RecipeStore.generate failed: $e');
      _pool = const [];
    } finally {
      _generating = false;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_setupKey, jsonEncode(_setup.toJson()));
      await prefs.setString(
        _poolKey,
        jsonEncode(_pool.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('RecipeStore.persist failed: $e');
    }
  }
}
