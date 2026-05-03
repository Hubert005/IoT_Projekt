import '../models/cocktail.dart';

/// Service interface for selecting a cocktail based on image analysis.
/// Production: Analyzes loser's photo and returns a matched cocktail.
abstract class CocktailService {
  Future<CocktailData> selectCocktail({required String loserImagePath});
}
