import 'package:flutter_test/flutter_test.dart';
import 'package:iot_drink_mixer/models/pump_setup.dart';
import 'package:iot_drink_mixer/services/recipe_generator_service.dart';

void main() {
  const generator = MockRecipeGeneratorService(delay: Duration.zero);
  const setup = PumpSetup(['Mango', 'Limette', 'Gin', 'Soda']);

  test('generates between 3 and 6 cocktails', () async {
    final cocktails = await generator.generate(setup);
    expect(cocktails.length, inInclusiveRange(3, 6));
  });

  test('pump amounts stay within bounds and use only the four pumps', () async {
    final cocktails = await generator.generate(setup);
    for (final c in cocktails) {
      expect(c.pumpAmounts.length, 4);
      for (final amount in c.pumpAmounts) {
        expect(amount, inInclusiveRange(0, 80));
      }
      expect(c.total, lessThanOrEqualTo(250));
      // At least two pumps actually contribute.
      expect(c.pumpAmounts.where((a) => a > 0).length, greaterThanOrEqualTo(2));
    }
  });

  test('is deterministic for the same setup', () async {
    final a = await generator.generate(setup);
    final b = await generator.generate(setup);
    expect(a.map((c) => c.name).toList(), b.map((c) => c.name).toList());
    expect(
      a.map((c) => c.pumpAmounts).toList(),
      b.map((c) => c.pumpAmounts).toList(),
    );
  });

  test('different setups produce different cocktails', () async {
    final a = await generator.generate(setup);
    final b = await generator.generate(const PumpSetup(['Wodka', 'Cola', 'Zitrone', 'Tonic']));
    expect(a.first.name, isNot(equals(b.first.name)));
  });

  test('cocktail names reference the entered ingredients', () async {
    final cocktails = await generator.generate(setup);
    // Every cocktail's hero ingredient must be one of the four pump drinks.
    for (final c in cocktails) {
      final mentionsIngredient =
          setup.drinks.any((d) => c.name.contains(d));
      expect(mentionsIngredient, isTrue, reason: c.name);
    }
  });
}
