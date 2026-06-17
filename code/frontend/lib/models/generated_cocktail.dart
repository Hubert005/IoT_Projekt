import 'cocktail.dart';
import 'drink.dart';
import 'pump_setup.dart';

/// A cocktail produced by the recipe generator from the current [PumpSetup].
///
/// [pumpAmounts] is the wire value sent verbatim as `mix_a_b_c_d` (one entry
/// per pump, index 0..3). No ml<->ms conversion happens anywhere — the value
/// is the pump run-time; the UI labels it as "ml" for the user.
class GeneratedCocktail {
  final String id;
  final String name;
  final String description;
  final List<String> tags; // mood tags used by the ML Kit selfie matcher
  final List<int> pumpAmounts; // length 4, index = pump
  final String refinementTip; // how the user could refine the drink

  const GeneratedCocktail({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.pumpAmounts,
    required this.refinementTip,
  });

  /// Total quantity across all pumps.
  int get total => pumpAmounts.fold(0, (sum, v) => sum + v);

  /// Human-readable ingredient lines, e.g. "Mango — 30 ml".
  /// Pumps with amount 0 are skipped.
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

  /// View used by the existing cocktail recommendation widget / ML matcher.
  CocktailData toCocktailData() => CocktailData(
        id: id,
        name: name,
        description: description,
        pairingTags: tags,
        recommendationReason: 'Aus deinen Zutaten für dich gemixt',
      );

  /// Mixer order. pumpAmounts are passed through unchanged (same unit as the
  /// hardcoded calibration drinks).
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
