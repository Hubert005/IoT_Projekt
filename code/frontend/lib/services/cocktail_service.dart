import '../models/cocktail.dart';

/// Service interface for selecting a cocktail based on image analysis.
/// Production: Analyzes loser's photo and returns a matched cocktail from the
/// given [candidates] (the pool generated from the current pump setup).
abstract class CocktailService {
  Future<CocktailData> selectCocktail({
    required String loserImagePath,
    required List<CocktailData> candidates,
  });
}
