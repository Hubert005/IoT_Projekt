import '../models/cocktail.dart';
import '../models/drink.dart';
import 'cocktail_service.dart';
import 'google_ml_kit_cocktail_service.dart';

/// Container for both cocktail recommendation and mixer drink data.
class DrinkSelectionResult {
  final CocktailData cocktail;
  final Drink drink;

  const DrinkSelectionResult({required this.cocktail, required this.drink});
}

/// Interface for determining the loser's drink.
/// Phase 2: Uses CocktailService for AI-based selection.
/// Production: call AI endpoint with loser's photo for personalised selection.
abstract class DrinkService {
  Future<Drink> selectDrink({
    required int loserPlayer,
    required String loserImagePath,
  });

  /// Get cocktail recommendation based on image analysis.
  /// Returns both the cocktail recommendation and mixer drink mapping.
  Future<DrinkSelectionResult> selectDrinkWithCocktail({
    required int loserPlayer,
    required String loserImagePath,
  });
}

/// Returns a drink based on cocktail AI analysis.
class MockDrinkService implements DrinkService {
  static const List<Drink> _drinks = [
    Drink(
      id: 'tropical_chaos',
      name: 'Tropical Chaos',
      ingredients: 'Mango, Ananas, Chili-Sirup & Soda',
      pumpAmounts: [30, 20, 10, 40],
    ),
    Drink(
      id: 'sour_loser',
      name: 'Sour Loser',
      ingredients: 'Zitrone, Himbeere, Ingwer & Tonic',
      pumpAmounts: [20, 30, 20, 30],
    ),
    Drink(
      id: 'blue_regret',
      name: 'Blue Regret',
      ingredients: 'Blaubeere, Limette, Minze & Sprudelwasser',
      pumpAmounts: [10, 40, 30, 20],
    ),
    Drink(
      id: 'bitter_defeat',
      name: 'Bitter Defeat',
      ingredients: 'Grapefruit, Rosmarin, Honig & Soda',
      pumpAmounts: [40, 10, 10, 40],
    ),
  ];

  final CocktailService _cocktailService;

  MockDrinkService({CocktailService? cocktailService})
    : _cocktailService = cocktailService ?? GoogleMLKitCocktailService();

  @override
  Future<Drink> selectDrink({
    required int loserPlayer,
    required String loserImagePath,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return _drinks[DateTime.now().second % _drinks.length];
  }

  @override
  Future<DrinkSelectionResult> selectDrinkWithCocktail({
    required int loserPlayer,
    required String loserImagePath,
  }) async {
    // Get cocktail recommendation from AI/ML
    final cocktail = await _cocktailService.selectCocktail(
      loserImagePath: loserImagePath,
    );

    // Map cocktail to mixer drink
    final drink = _mapCocktailToDrink(cocktail);

    return DrinkSelectionResult(cocktail: cocktail, drink: drink);
  }

  /// Map cocktail ID to mixer drink.
  Drink _mapCocktailToDrink(CocktailData cocktail) {
    return switch (cocktail.id) {
      'tropical_chaos' => _drinks[0],
      'sour_loser' => _drinks[1],
      'blue_regret' => _drinks[2],
      'bitter_defeat' => _drinks[3],
      _ => _drinks[0],
    };
  }
}
