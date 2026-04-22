class Drink {
  final String id;
  final String name;
  final String ingredients;
  final List<int> pumpAmounts; // ml per pump: [pump0, pump1, pump2, pump3]

  const Drink({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.pumpAmounts,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
