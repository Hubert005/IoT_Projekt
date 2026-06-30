import 'dart:math';

import '../models/generated_cocktail.dart';
import '../models/pump_setup.dart';

abstract class RecipeGeneratorService {
  Future<List<GeneratedCocktail>> generate(PumpSetup setup);
}

const int _maxPerPump = 80;
const int _minPerPump = 20;
const int _maxTotal = 250;

class MockRecipeGeneratorService implements RecipeGeneratorService {
  final Duration delay;

  const MockRecipeGeneratorService({this.delay = const Duration(milliseconds: 600)});

  static const List<_Style> _styles = [
    _Style('Wild', 'Smash', ['happy', 'bold', 'tropical', 'playful'],
        'Mit ein paar Eiswürfeln und einem Spritzer Limette abrunden.'),
    _Style('Midnight', 'Mule', ['mysterious', 'intense', 'dark', 'serious'],
        'Mit etwas Ginger Beer aufgießen für mehr Schärfe.'),
    _Style('Sunny', 'Fizz', ['happy', 'fresh', 'light', 'colorful'],
        'Mit Soda toppen und mit einer Orangenscheibe garnieren.'),
    _Style('Velvet', 'Sour', ['sophisticated', 'calm', 'warm', 'classic'],
        'Einen Spritzer Zitrone für mehr Säure hinzufügen.'),
    _Style('Electric', 'Punch', ['energetic', 'colorful', 'bold', 'young'],
        'Gut auf Eis shaken und kalt servieren.'),
    _Style('Frosted', 'Cooler', ['fresh', 'light', 'calm', 'colorful'],
        'Crushed Ice verwenden und mit Minze verfeinern.'),
  ];

  @override
  Future<List<GeneratedCocktail>> generate(PumpSetup setup) async {
    if (delay > Duration.zero) await Future.delayed(delay);

    final names = setup.drinks.map((d) => d.trim()).toList();
    final rng = Random(_seedFor(names));

    final count = 3 + rng.nextInt(4); // 3..6
    final styles = List<_Style>.from(_styles)..shuffle(rng);

    final cocktails = <GeneratedCocktail>[];
    for (var i = 0; i < count; i++) {
      final style = styles[i % styles.length];
      final amounts = _randomAmounts(rng);
      final heroPump = _heroPump(amounts);
      final heroName = names[heroPump].isEmpty ? 'Pumpe ${heroPump + 1}' : names[heroPump];

      final cocktailName = '${style.adj} $heroName ${style.suffix}';
      final used = <String>[];
      for (var p = 0; p < amounts.length; p++) {
        if (amounts[p] > 0) {
          used.add(names[p].isEmpty ? 'Pumpe ${p + 1}' : names[p]);
        }
      }

      cocktails.add(GeneratedCocktail(
        id: 'gen_${i}_${_seedFor(names)}',
        name: cocktailName,
        description: 'Ein Mix aus ${used.join(', ')}.',
        tags: style.tags,
        pumpAmounts: amounts,
        refinementTip: style.tip,
      ));
    }
    return cocktails;
  }

  List<int> _randomAmounts(Random rng) {
    final amounts = List<int>.filled(4, 0);
    final pumps = [0, 1, 2, 3]..shuffle(rng);
    final usedCount = 2 + rng.nextInt(3); // 2..4

    for (var i = 0; i < usedCount; i++) {
      amounts[pumps[i]] = _minPerPump + rng.nextInt(_maxPerPump - _minPerPump + 1);
    }

    final total = amounts.fold(0, (s, v) => s + v);
    if (total > _maxTotal) {
      final scale = _maxTotal / total;
      for (var i = 0; i < amounts.length; i++) {
        if (amounts[i] > 0) amounts[i] = (amounts[i] * scale).floor();
      }
    }
    return amounts;
  }

  int _heroPump(List<int> amounts) {
    var hero = 0;
    for (var i = 1; i < amounts.length; i++) {
      if (amounts[i] > amounts[hero]) hero = i;
    }
    return hero;
  }

  int _seedFor(List<String> names) {
    var seed = 7;
    for (final code in names.join('|').toLowerCase().codeUnits) {
      seed = (seed * 31 + code) & 0x7fffffff;
    }
    return seed;
  }
}

class _Style {
  final String adj;
  final String suffix;
  final List<String> tags;
  final String tip;

  const _Style(this.adj, this.suffix, this.tags, this.tip);
}
