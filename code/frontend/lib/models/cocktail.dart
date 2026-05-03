/// Represents a cocktail recommendation based on AI analysis.
/// This is distinct from [Drink] which focuses on mixer pump amounts.
class CocktailData {
  final String id;
  final String name;
  final String description;
  final List<String>
  pairingTags; // Tags for AI matching (e.g., "happy", "blue", "energetic")
  final String recommendationReason; // Why this cocktail was chosen

  const CocktailData({
    required this.id,
    required this.name,
    required this.description,
    required this.pairingTags,
    this.recommendationReason = 'Speziell für dich ausgewählt',
  });
}
