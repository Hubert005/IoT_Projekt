import 'dart:math';

import '../models/cocktail.dart';
import 'cocktail_service.dart';

class MockCocktailService implements CocktailService {
  @override
  Future<CocktailData> selectCocktail({
    required String loserImagePath,
    required List<CocktailData> candidates,
  }) async {
    // Simulate analysis delay.
    await Future.delayed(const Duration(milliseconds: 500));
    if (candidates.isEmpty) {
      throw StateError('selectCocktail requires a non-empty candidate pool');
    }
    return candidates[Random().nextInt(candidates.length)];
  }
}
