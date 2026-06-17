import 'package:flutter_test/flutter_test.dart';
import 'package:iot_drink_mixer/models/generated_cocktail.dart';
import 'package:iot_drink_mixer/models/pump_setup.dart';
import 'package:iot_drink_mixer/services/recipe_generator_service.dart';
import 'package:iot_drink_mixer/services/recipe_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts how often generate() is called so we can assert invalidation.
class _CountingGenerator implements RecipeGeneratorService {
  int calls = 0;

  @override
  Future<List<GeneratedCocktail>> generate(PumpSetup setup) async {
    calls++;
    return [
      GeneratedCocktail(
        id: 'c_${setup.drinks.join("_")}',
        name: 'Test ${setup.drinks.first}',
        description: 'desc',
        tags: const ['happy'],
        pumpAmounts: const [30, 20, 10, 40],
        refinementTip: 'tip',
      ),
    ];
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('generates a pool when the setup is completed', () async {
    final gen = _CountingGenerator();
    final store = RecipeStore.forTesting(generator: gen);

    await store.updateSetupAndRegenerate(const PumpSetup(['a', 'b', 'c', 'd']));

    expect(store.hasPool, isTrue);
    expect(gen.calls, 1);
  });

  test('does not regenerate when the setup is unchanged', () async {
    final gen = _CountingGenerator();
    final store = RecipeStore.forTesting(generator: gen);

    await store.updateSetupAndRegenerate(const PumpSetup(['a', 'b', 'c', 'd']));
    await store.updateSetupAndRegenerate(const PumpSetup(['a', 'b', 'c', 'd']));

    expect(gen.calls, 1);
  });

  test('regenerates when a pump drink changes', () async {
    final gen = _CountingGenerator();
    final store = RecipeStore.forTesting(generator: gen);

    await store.updateSetupAndRegenerate(const PumpSetup(['a', 'b', 'c', 'd']));
    await store.updateSetupAndRegenerate(const PumpSetup(['a', 'b', 'c', 'X']));

    expect(gen.calls, 2);
  });

  test('persists setup and pool across instances', () async {
    final store1 = RecipeStore.forTesting(generator: _CountingGenerator());
    await store1.updateSetupAndRegenerate(const PumpSetup(['a', 'b', 'c', 'd']));

    final store2 = RecipeStore.forTesting(generator: _CountingGenerator());
    await store2.load();

    expect(store2.setup.drinks, ['a', 'b', 'c', 'd']);
    expect(store2.hasPool, isTrue);
    expect(store2.pool.first.pumpAmounts, [30, 20, 10, 40]);
  });

  test('incomplete setup clears the pool', () async {
    final store = RecipeStore.forTesting(generator: _CountingGenerator());
    await store.updateSetupAndRegenerate(const PumpSetup(['a', 'b', 'c', 'd']));
    expect(store.hasPool, isTrue);

    await store.updateSetupAndRegenerate(const PumpSetup(['a', '', 'c', 'd']));
    expect(store.hasPool, isFalse);
  });
}
