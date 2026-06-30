class CocktailData {
  final String id;
  final String name;
  final String description;
  final List<String>
  pairingTags;
  final String recommendationReason;

  const CocktailData({
    required this.id,
    required this.name,
    required this.description,
    required this.pairingTags,
    this.recommendationReason = 'Speziell für dich ausgewählt',
  });
}
