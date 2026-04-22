import '../models/drink.dart';

/// Interface for determining the loser's drink.
/// Production: call AI endpoint with loser's photo for personalised selection.
abstract class DrinkService {
  Future<Drink> selectDrink({
    required int loserPlayer,
    required String loserImagePath,
  });
}

/// Returns a random drink without any real AI analysis.
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

  @override
  Future<Drink> selectDrink({
    required int loserPlayer,
    required String loserImagePath,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return _drinks[DateTime.now().second % _drinks.length];
  }
}
