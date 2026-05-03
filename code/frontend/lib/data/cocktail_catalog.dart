import '../models/cocktail.dart';

/// Hardcoded catalog of available cocktails.
/// Each cocktail has AI pairing tags to match with player image analysis results.
class CocktailCatalog {
  static const List<CocktailData> cocktails = [
    CocktailData(
      id: 'long_island',
      name: 'Long Island Iced Tea',
      description:
          'Kraftvoll und komplex. Ein Mix aus 5 verschiedenen Spirituosen, Zitrone und Cola. Definitiv nicht für schwache Nerven.',
      pairingTags: ['confident', 'energetic', 'dark', 'serious', 'complex'],
      recommendationReason:
          'Du wirkst mutig und energiegeladen — Zeit für den Klassiker unter den Shots!',
    ),
    CocktailData(
      id: 'old_fashioned',
      name: 'Old Fashioned',
      description:
          'Der Klassiker für elegante Genießer. Whiskey, Zucker, Bitter und Eis. Rustikal und würdig.',
      pairingTags: ['sophisticated', 'calm', 'warm', 'neutral', 'traditional'],
      recommendationReason:
          'Du strahlst Eleganz aus — der Old Fashioned ist perfekt für deinen Geschmack.',
    ),
    CocktailData(
      id: 'mojito',
      name: 'Mojito',
      description:
          'Erfrischend und lebendig. Weiße Rum, Minze, Limette, Zucker und Wasser. Der Sommer im Glas.',
      pairingTags: ['happy', 'light', 'fresh', 'young', 'colorful', 'playful'],
      recommendationReason:
          'Dein fröhlicher Ausdruck verdient etwas Erfrischendes — Mojito ist perfekt!',
    ),
    CocktailData(
      id: 'zombie',
      name: 'Zombie',
      description:
          'Intensiv und geheimnisvoll. Mehrere Rumarten, Fruchtsäfte und Gewürze. Ein tropisches Abenteuer.',
      pairingTags: ['intense', 'mysterious', 'adventurous', 'bold', 'tropical'],
      recommendationReason:
          'Du wirkst abenteuerlustig — der Zombie ist deine perfekte Herausforderung!',
    ),
  ];

  /// Get a cocktail by ID.
  static CocktailData? getById(String id) {
    try {
      return cocktails.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get a random cocktail.
  static CocktailData getRandom() {
    return cocktails[DateTime.now().second % cocktails.length];
  }
}
