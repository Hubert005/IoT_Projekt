import 'package:flutter_test/flutter_test.dart';
import 'package:iot_drink_mixer/models/generated_cocktail.dart';
import 'package:iot_drink_mixer/models/pump_setup.dart';

void main() {
  group('PumpSetup', () {
    test('isComplete only when all four pumps are filled', () {
      expect(const PumpSetup(['a', 'b', 'c', 'd']).isComplete, isTrue);
      expect(const PumpSetup(['a', '', 'c', 'd']).isComplete, isFalse);
      expect(PumpSetup.empty().isComplete, isFalse);
    });

    test('sameAs ignores case and surrounding whitespace', () {
      expect(
        const PumpSetup(['Mango', 'Limette', 'Gin', 'Soda'])
            .sameAs(const PumpSetup([' mango ', 'LIMETTE', 'gin', 'Soda'])),
        isTrue,
      );
      expect(
        const PumpSetup(['Mango', 'Limette', 'Gin', 'Soda'])
            .sameAs(const PumpSetup(['Mango', 'Limette', 'Gin', 'Tonic'])),
        isFalse,
      );
    });

    test('json round-trip', () {
      const setup = PumpSetup(['a', 'b', 'c', 'd']);
      expect(PumpSetup.fromJson(setup.toJson()).drinks, setup.drinks);
    });
  });

  group('GeneratedCocktail', () {
    const setup = PumpSetup(['Mango', 'Limette', 'Gin', 'Soda']);
    const cocktail = GeneratedCocktail(
      id: 'x',
      name: 'Wild Mango Smash',
      description: 'desc',
      tags: ['happy'],
      pumpAmounts: [40, 0, 20, 10],
      refinementTip: 'tip',
    );

    test('total sums the pump amounts', () {
      expect(cocktail.total, 70);
    });

    test('ingredientLines skips empty pumps and shows ml', () {
      final lines = cocktail.ingredientLines(setup);
      expect(lines, ['Mango — 40 ml', 'Gin — 20 ml', 'Soda — 10 ml']);
    });

    test('toDrink passes pump amounts through unchanged', () {
      expect(cocktail.toDrink().pumpAmounts, [40, 0, 20, 10]);
    });

    test('json round-trip preserves data', () {
      final back = GeneratedCocktail.fromJson(cocktail.toJson());
      expect(back.name, cocktail.name);
      expect(back.pumpAmounts, cocktail.pumpAmounts);
      expect(back.tags, cocktail.tags);
      expect(back.refinementTip, cocktail.refinementTip);
    });
  });
}
