import '../data/cocktail_catalog.dart';
import '../models/cocktail.dart';
import '../models/drink.dart';
import '../models/generated_cocktail.dart';
import 'cocktail_service.dart';
import 'google_ml_kit_cocktail_service.dart';
import 'recipe_store.dart';

class DrinkSelectionResult {
  final CocktailData cocktail;
  final Drink drink;

  const DrinkSelectionResult({required this.cocktail, required this.drink});
}

abstract class DrinkService {
  Future<Drink> selectDrink({
    required int loserPlayer,
    required String loserImagePath,
  });

  Future<DrinkSelectionResult> selectDrinkWithCocktail({
    required int loserPlayer,
    required String loserImagePath,
  });
}

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
  final RecipeStore _recipeStore;

  MockDrinkService({CocktailService? cocktailService, RecipeStore? recipeStore})
      : _cocktailService = cocktailService ?? GoogleMLKitCocktailService(),
        _recipeStore = recipeStore ?? RecipeStore.instance;

  @override
  Future<Drink> selectDrink({
    required int loserPlayer,
    required String loserImagePath,
  }) async {
    final result = await selectDrinkWithCocktail(
      loserPlayer: loserPlayer,
      loserImagePath: loserImagePath,
    );
    return result.drink;
  }

  @override
  Future<DrinkSelectionResult> selectDrinkWithCocktail({
    required int loserPlayer,
    required String loserImagePath,
  }) async {
    final pool = _recipeStore.pool;

    if (pool.isNotEmpty) {
      final byId = {for (final c in pool) c.id: c};
      final selected = await _cocktailService.selectCocktail(
        loserImagePath: loserImagePath,
        candidates: pool.map((c) => c.toCocktailData()).toList(),
      );
      final GeneratedCocktail chosen = byId[selected.id] ?? pool.first;
      return DrinkSelectionResult(cocktail: chosen.toCocktailData(), drink: chosen.toDrink());
    }

    final cocktail = await _cocktailService.selectCocktail(
      loserImagePath: loserImagePath,
      candidates: CocktailCatalog.cocktails,
    );
    return DrinkSelectionResult(cocktail: cocktail, drink: _mapCocktailToDrink(cocktail));
  }

  Drink _mapCocktailToDrink(CocktailData cocktail) {
    return switch (cocktail.id) {
      'long_island' => _drinks[0],
      'old_fashioned' => _drinks[1],
      'mojito' => _drinks[2],
      'zombie' => _drinks[3],
      _ => _drinks[0],
    };
  }
}
