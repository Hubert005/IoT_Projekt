enum RecipeFilter { all, available, favorites }

enum RecipeStatus { ready, lowStock, refillRequired }

class RecipeItem {
  final String name;
  final String subtitle;
  final String volumeAndTime;
  final RecipeStatus status;
  final bool aiRecommended;
  final bool favorite;
  final String imageUrl;

  const RecipeItem({
    required this.name,
    required this.subtitle,
    required this.volumeAndTime,
    required this.status,
    required this.aiRecommended,
    required this.favorite,
    required this.imageUrl,
  });
}
