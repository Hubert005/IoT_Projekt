class PumpSetup {
  final List<String> drinks;

  const PumpSetup(this.drinks);

  factory PumpSetup.empty() => const PumpSetup(['', '', '', '']);

  bool get isComplete => drinks.length == 4 && drinks.every((d) => d.trim().isNotEmpty);

  String drinkAt(int pump) => (pump >= 0 && pump < drinks.length) ? drinks[pump] : '';

  PumpSetup copyWith({List<String>? drinks}) => PumpSetup(drinks ?? this.drinks);

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
