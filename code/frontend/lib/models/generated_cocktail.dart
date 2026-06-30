import 'cocktail.dart';
import 'drink.dart';
import 'pump_setup.dart';

class GeneratedCocktail {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final List<int> pumpAmounts;
  final String refinementTip;

  const GeneratedCocktail({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.pumpAmounts,
    required this.refinementTip,
  });

  int get total => pumpAmounts.fold(0, (sum, v) => sum + v);

  List<String> ingredientLines(PumpSetup setup) {
    final lines = <String>[];
    for (var i = 0; i < pumpAmounts.length; i++) {
      final amount = pumpAmounts[i];
      if (amount <= 0) continue;
      final name = setup.drinkAt(i).trim();
      lines.add('${name.isEmpty ? 'Pumpe ${i + 1}' : name} — $amount ml');
    }
    return lines;
  }

  CocktailData toCocktailData() => CocktailData(
        id: id,
        name: name,
        description: description,
        pairingTags: tags,
        recommendationReason: 'Aus deinen Zutaten für dich gemixt',
      );

  Drink toDrink() => Drink(
        id: id,
        name: name,
        ingredients: description,
        pumpAmounts: pumpAmounts,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'tags': tags,
        'pumpAmounts': pumpAmounts,
        'refinementTip': refinementTip,
      };

  factory GeneratedCocktail.fromJson(Map<String, dynamic> json) => GeneratedCocktail(
        id: json['id'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        tags: ((json['tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
        pumpAmounts: ((json['pumpAmounts'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        refinementTip: (json['refinementTip'] as String?) ?? '',
      );
}
