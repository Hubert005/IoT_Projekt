import 'package:flutter/foundation.dart';

import '../data/cocktail_catalog.dart';
import '../models/cocktail.dart';
import 'cocktail_service.dart';
import 'image_analyzer_service.dart';

/// Real ML Kit implementation of CocktailService.
/// Analyzes loser's photo and matches it to a cocktail using ML-based scoring.
class GoogleMLKitCocktailService implements CocktailService {
  final ImageAnalyzerService _analyzer;

  GoogleMLKitCocktailService({ImageAnalyzerService? analyzer})
    : _analyzer = analyzer ?? ImageAnalyzerService();

  @override
  Future<CocktailData> selectCocktail({required String loserImagePath}) async {
    try {
      // Ensure analyzer is initialized
      await _analyzer.initialize();

      // Analyze the loser's image
      final profile = await _analyzer.analyzeImage(loserImagePath);

      if (!profile.faceDetected) {
        // Fallback: return random cocktail if no face detected
        return CocktailCatalog.getRandom();
      }

      // Score each cocktail based on image profile
      final scores = <String, double>{
        'long_island': _scoreLongIsland(profile),
        'old_fashioned': _scoreOldFashioned(profile),
        'mojito': _scoreMojito(profile),
        'zombie': _scoreZombie(profile),
      };

      // Find best match
      final bestId =
          scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final selected =
          CocktailCatalog.getById(bestId) ?? CocktailCatalog.getRandom();

      return selected;
    } catch (e) {
      debugPrint('Error in GoogleMLKitCocktailService: $e');
      // Fallback to random on error
      return CocktailCatalog.getRandom();
    }
  }

  /// Score for "Long Island Iced Tea" - confident, energetic, bold
  double _scoreLongIsland(ImageProfile profile) {
    double score = 0.0;

    // High confidence for strong/serious expressions
    if (profile.emotion == 'neutral' || profile.emotion == 'sad') {
      score += 0.3; // Neutral/serious → complex drink
    }

    // Head turned away or tilted → confident posture
    if (profile.headEulerAngleY != null &&
        profile.headEulerAngleY!.abs() > 15) {
      score += 0.2; // Turned head suggests confidence
    }

    // Dark/serious labels
    if (_labelsContain(profile, ['dark', 'serious', 'intense', 'bold'])) {
      score += 0.3;
    }

    // Eyes open = alert/aware
    final avgEyeOpen =
        ((profile.estimatedLeftEyeOpen ?? 0.5) +
            (profile.estimatedRightEyeOpen ?? 0.5)) /
        2;
    score += avgEyeOpen * 0.2;

    return score;
  }

  /// Score for "Old Fashioned" - sophisticated, calm, warm
  double _scoreOldFashioned(ImageProfile profile) {
    double score = 0.0;

    // Neutral expression preferred
    if (profile.emotion == 'neutral') {
      score += 0.4;
    }

    // Warm/vintage labels
    if (_labelsContain(profile, [
      'warm',
      'brown',
      'vintage',
      'classic',
      'wood',
    ])) {
      score += 0.3;
    }

    // Calm posture (head not too tilted)
    if (profile.headEulerAngleZ != null &&
        profile.headEulerAngleZ!.abs() < 10) {
      score += 0.2;
    }

    // Slight smile ok, not big grin
    if (profile.estimatedSmile != null &&
        profile.estimatedSmile! > 0.2 &&
        profile.estimatedSmile! < 0.5) {
      score += 0.2;
    }

    return score;
  }

  /// Score for "Mojito" - happy, fresh, light, colorful
  double _scoreMojito(ImageProfile profile) {
    double score = 0.0;

    // Happy expression is key
    if (profile.emotion == 'happy') {
      score += 0.5; // Strong preference for smiling
    }

    // Bright/fresh labels
    if (_labelsContain(profile, [
      'light',
      'green',
      'blue',
      'fresh',
      'colorful',
      'bright',
      'young',
    ])) {
      score += 0.3;
    }

    // Wide eyes = energetic
    final avgEyeOpen =
        ((profile.estimatedLeftEyeOpen ?? 0.5) +
            (profile.estimatedRightEyeOpen ?? 0.5)) /
        2;
    if (avgEyeOpen > 0.7) {
      score += 0.2;
    }

    // Direct head position (not turned away)
    if (profile.headEulerAngleY != null &&
        profile.headEulerAngleY!.abs() < 20) {
      score += 0.1;
    }

    return score;
  }

  /// Score for "Zombie" - adventurous, bold, tropical, mysterious
  double _scoreZombie(ImageProfile profile) {
    double score = 0.0;

    // Both happy and intense work
    if (profile.emotion == 'happy') {
      score += 0.25; // Playful energy
    } else if (profile.emotion == 'sad' || profile.emotion == 'neutral') {
      score += 0.2; // Mysterious mood
    }

    // Tropical/exotic labels
    if (_labelsContain(profile, [
      'tropical',
      'exotic',
      'colorful',
      'orange',
      'red',
      'yellow',
    ])) {
      score += 0.35;
    }

    // Adventurous = head turned or tilted
    if (profile.headEulerAngleY != null &&
        profile.headEulerAngleY!.abs() > 10) {
      score += 0.15;
    }
    if (profile.headEulerAngleZ != null && profile.headEulerAngleZ!.abs() > 8) {
      score += 0.15;
    }

    return score;
  }

  /// Helper: Check if labels list contains any of the search terms
  bool _labelsContain(ImageProfile profile, List<String> searchTerms) {
    final lowerLabels = profile.labels.map((l) => l.toLowerCase()).toList();
    return searchTerms.any(
      (term) => lowerLabels.any((label) => label.contains(term.toLowerCase())),
    );
  }
}
