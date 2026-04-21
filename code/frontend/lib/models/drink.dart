class Drink {
  final String id;
  final String name;
  final String ingredients;

  const Drink({
    required this.id,
    required this.name,
    required this.ingredients,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
