enum RecipeFilter { all, available, favorites }

enum RecipeStatus { ready, lowStock, refillRequired }

class RecipeIngredient {
  final String name;
  final int amountMl;

  const RecipeIngredient({required this.name, required this.amountMl});
}

class RecipeItem {
  final String name;
  final String subtitle;
  final RecipeStatus status;
  final bool aiRecommended;
  final bool favorite;
  final String imageUrl;
  final List<RecipeIngredient> ingredients;

  const RecipeItem({
    required this.name,
    required this.subtitle,
    required this.status,
    required this.aiRecommended,
    required this.favorite,
    required this.imageUrl,
    required this.ingredients,
  });

  int get totalVolumeMl => ingredients.fold(0, (sum, item) => sum + item.amountMl);

  String get mixSummary => ingredients.map((item) => '${item.name} ${item.amountMl} ml').join(' • ');
}
