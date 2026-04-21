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
    ),
    Drink(
      id: 'sour_loser',
      name: 'Sour Loser',
      ingredients: 'Zitrone, Himbeere, Ingwer & Tonic',
    ),
    Drink(
      id: 'blue_regret',
      name: 'Blue Regret',
      ingredients: 'Blaubeere, Limette, Minze & Sprudelwasser',
    ),
    Drink(
      id: 'bitter_defeat',
      name: 'Bitter Defeat',
      ingredients: 'Grapefruit, Rosmarin, Honig & Soda',
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

// ── Real implementation stub ───────────────────────────────────────────────
// class AiDrinkService implements DrinkService {
//   @override
//   Future<Drink> selectDrink({required int loserPlayer, required String loserImagePath}) async {
//     final bytes = await File(loserImagePath).readAsBytes();
//     final res = await http.post(
//       Uri.parse('http://mixer.local/ai/drink'),
//       body: {'player': '$loserPlayer', 'photo': base64Encode(bytes)},
//     );
//     final data = jsonDecode(res.body);
//     return Drink(id: data['id'], name: data['name'], ingredients: data['ingredients']);
//   }
// }
