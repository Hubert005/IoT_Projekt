import 'package:flutter_test/flutter_test.dart';
import 'package:iot_drink_mixer/models/generated_cocktail.dart';
import 'package:iot_drink_mixer/models/mood_tags.dart';
import 'package:iot_drink_mixer/models/pump_setup.dart';
import 'package:iot_drink_mixer/services/gemma_recipe_parsing.dart';

/// Deterministic tests for the model-free parsing/sanitizing layer. They assert
/// that whatever the on-device LLM emits is forced back into the same contract
/// the MockRecipeGeneratorService tests enforce — without ever loading a model.
void main() {
  const setup = PumpSetup(['Mango', 'Limette', 'Gin', 'Soda']);

  void expectValidContract(List<GeneratedCocktail> cocktails) {
    expect(cocktails.length, lessThanOrEqualTo(6));
    for (final c in cocktails) {
      expect(c.pumpAmounts.length, 4);
      for (final amount in c.pumpAmounts) {
        expect(amount, inInclusiveRange(0, 80));
      }
      expect(c.total, lessThanOrEqualTo(250));
      expect(c.pumpAmounts.where((a) => a > 0).length, greaterThanOrEqualTo(2));
      expect(c.tags, isNotEmpty);
      for (final t in c.tags) {
        expect(kMoodTags, contains(t));
      }
      final mentionsIngredient = setup.drinks.any((d) => c.name.contains(d));
      expect(mentionsIngredient, isTrue, reason: c.name);
    }
  }

  test('parses a clean JSON array', () {
    const raw = '''
[
  {"name":"Mango Smash","description":"Frisch.","tags":["happy","fresh"],"pumpAmounts":[60,40,0,30],"refinementTip":"Eis dazu."},
  {"name":"Gin Cooler","description":"Herb.","tags":["bold"],"pumpAmounts":[0,20,50,40],"refinementTip":"Minze."},
  {"name":"Limette Fizz","description":"Spritzig.","tags":["light"],"pumpAmounts":[30,30,0,30],"refinementTip":"Soda."}
]''';
    final cocktails = parseGemmaCocktails(raw, setup);
    expect(cocktails.length, 3);
    expectValidContract(cocktails);
  });

  test('extracts JSON from prose and markdown fences', () {
    const raw = '''
Klar! Hier sind deine Cocktails:
```json
[{"name":"Mango Mix","description":"","tags":["happy"],"pumpAmounts":[40,40,0,0],"refinementTip":""}]
```
Viel Spaß!''';
    final cocktails = parseGemmaCocktails(raw, setup);
    expect(cocktails.length, 1);
    expectValidContract(cocktails);
  });

  test('clamps out-of-range amounts and scales down oversized totals', () {
    final cocktails = sanitizeCocktails([
      {
        'name': 'Mango Bomb',
        'tags': ['happy'],
        'pumpAmounts': [999, 999, 999, 999], // all over max and total
      },
    ], setup);
    expectValidContract(cocktails);
  });

  test('fills pumps when fewer than two are used', () {
    final cocktails = sanitizeCocktails([
      {
        'name': 'Mango Solo',
        'tags': ['happy'],
        'pumpAmounts': [50, 0, 0, 0], // only one pump
      },
    ], setup);
    expect(cocktails.single.pumpAmounts.where((a) => a > 0).length,
        greaterThanOrEqualTo(2));
    expectValidContract(cocktails);
  });

  test('drops tags outside the mood vocabulary and defaults when empty', () {
    final cocktails = sanitizeCocktails([
      {
        'name': 'Mango Thing',
        'tags': ['delicious', 'spicy', 'happy'], // first two invalid
        'pumpAmounts': [40, 40, 0, 0],
      },
      {
        'name': 'Gin Thing',
        'tags': <String>[], // empty -> default
        'pumpAmounts': [0, 0, 40, 40],
      },
    ], setup);
    expect(cocktails[0].tags, ['happy']);
    expect(cocktails[1].tags, isNotEmpty);
    expectValidContract(cocktails);
  });

  test('prefixes a hero ingredient when the name omits all ingredients', () {
    final cocktails = sanitizeCocktails([
      {
        'name': 'Mystery Drink',
        'tags': ['bold'],
        'pumpAmounts': [70, 10, 0, 0], // hero = Mango (pump 0)
      },
    ], setup);
    expect(cocktails.single.name.contains('Mango'), isTrue);
    expectValidContract(cocktails);
  });

  test('caps the pool at six cocktails', () {
    final items = List.generate(
      10,
      (i) => {
        'name': 'Mango $i',
        'tags': ['happy'],
        'pumpAmounts': [40, 40, 0, 0],
      },
    );
    final cocktails = sanitizeCocktails(items, setup);
    expect(cocktails.length, 6);
    expectValidContract(cocktails);
  });

  test('throws FormatException when no JSON is present', () {
    expect(() => parseGemmaCocktails('Entschuldigung, ich kann das nicht.', setup),
        throwsFormatException);
  });
}
