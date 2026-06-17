/// Which drink sits at each of the 4 pumps.
///
/// Index = pump number (0..3). The names are free text entered by the user
/// via the "What's in the box" overlay; they are the only ingredients the
/// recipe generator is allowed to use.
class PumpSetup {
  final List<String> drinks; // length 4, index = pump

  const PumpSetup(this.drinks);

  /// Empty setup with four blank pumps.
  factory PumpSetup.empty() => const PumpSetup(['', '', '', '']);

  /// True once every pump has a non-empty drink assigned.
  bool get isComplete => drinks.length == 4 && drinks.every((d) => d.trim().isNotEmpty);

  /// Name of the drink on [pump] (0..3), or '' if out of range.
  String drinkAt(int pump) => (pump >= 0 && pump < drinks.length) ? drinks[pump] : '';

  PumpSetup copyWith({List<String>? drinks}) => PumpSetup(drinks ?? this.drinks);

  /// Same ingredients in the same pump order. Used to decide whether the
  /// generated pool is still valid after the user edits the overlay.
  bool sameAs(PumpSetup other) {
    if (drinks.length != other.drinks.length) return false;
    for (var i = 0; i < drinks.length; i++) {
      if (drinks[i].trim().toLowerCase() != other.drinks[i].trim().toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {'drinks': drinks};

  factory PumpSetup.fromJson(Map<String, dynamic> json) {
    final raw = (json['drinks'] as List?) ?? const [];
    final list = raw.map((e) => e.toString()).toList();
    while (list.length < 4) {
      list.add('');
    }
    return PumpSetup(list.take(4).toList());
  }
}
