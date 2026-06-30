import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/cocktail.dart';
import 'cocktail_service.dart';
import 'image_analyzer_service.dart';

class GoogleMLKitCocktailService implements CocktailService {
  final ImageAnalyzerService _analyzer;

  GoogleMLKitCocktailService({ImageAnalyzerService? analyzer})
      : _analyzer = analyzer ?? ImageAnalyzerService();

  @override
  Future<CocktailData> selectCocktail({
    required String loserImagePath,
    required List<CocktailData> candidates,
  }) async {
    assert(candidates.isNotEmpty, 'selectCocktail requires a non-empty pool');
    if (candidates.length == 1) return candidates.first;

    try {
      await _analyzer.initialize();
      final profile = await _analyzer.analyzeImage(loserImagePath);

      if (!profile.faceDetected) {
        return candidates[Random().nextInt(candidates.length)];
      }

      final weights = _moodWeights(profile);

      CocktailData best = candidates.first;
      double bestScore = double.negativeInfinity;
      for (final c in candidates) {
        final score = _scoreByTags(c.pairingTags, weights);
        if (score > bestScore) {
          bestScore = score;
          best = c;
        }
      }
      return best;
    } catch (e) {
      debugPrint('Error in GoogleMLKitCocktailService: $e');
      return candidates[Random().nextInt(candidates.length)];
    }
  }

  double _scoreByTags(List<String> tags, Map<String, double> weights) {
    double score = 0;
    for (final tag in tags) {
      score += (weights[tag.toLowerCase()] ?? 0.0) + 0.01;
    }
    return score;
  }

  Map<String, double> _moodWeights(ImageProfile profile) {
    final w = <String, double>{};
    void add(String tag, double v) => w[tag] = (w[tag] ?? 0) + v;

    // Expression / emotion.
    switch (profile.emotion) {
      case 'happy':
        for (final t in ['happy', 'fresh', 'light', 'colorful', 'playful', 'young']) {
          add(t, 0.5);
        }
        break;
      case 'neutral':
        for (final t in ['sophisticated', 'calm', 'warm', 'classic', 'traditional']) {
          add(t, 0.4);
        }
        break;
      case 'sad':
        for (final t in ['dark', 'serious', 'mysterious', 'intense', 'complex']) {
          add(t, 0.4);
        }
        break;
    }

    final avgEyeOpen =
        ((profile.estimatedLeftEyeOpen ?? 0.5) + (profile.estimatedRightEyeOpen ?? 0.5)) / 2;
    if (avgEyeOpen > 0.7) {
      for (final t in ['energetic', 'bold', 'adventurous']) {
        add(t, 0.3);
      }
    }

    if ((profile.headEulerAngleY ?? 0).abs() > 15 || (profile.headEulerAngleZ ?? 0).abs() > 10) {
      for (final t in ['confident', 'bold', 'adventurous', 'intense']) {
        add(t, 0.25);
      }
    }

    const labelTagMap = {
      'tropical': ['tropical', 'colorful', 'adventurous'],
      'green': ['fresh', 'light'],
      'blue': ['fresh', 'calm'],
      'orange': ['colorful', 'energetic'],
      'red': ['bold', 'intense'],
      'yellow': ['happy', 'colorful'],
      'dark': ['dark', 'serious', 'mysterious'],
      'wood': ['warm', 'classic', 'traditional'],
      'bright': ['light', 'fresh', 'colorful'],
    };
    labelTagMap.forEach((label, tags) {
      if (_labelsContain(profile, [label])) {
        for (final t in tags) {
          add(t, 0.3);
        }
      }
    });

    return w;
  }

  bool _labelsContain(ImageProfile profile, List<String> searchTerms) {
    final lowerLabels = profile.labels.map((l) => l.toLowerCase()).toList();
    return searchTerms.any(
      (term) => lowerLabels.any((label) => label.contains(term.toLowerCase())),
    );
  }
}
