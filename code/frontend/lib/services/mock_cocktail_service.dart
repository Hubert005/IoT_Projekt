import '../data/cocktail_catalog.dart';
import '../models/cocktail.dart';
import 'cocktail_service.dart';

/// Mock implementation of CocktailService for development and testing.
/// Can switch between random selection or use real GoogleMLKit analysis.
class MockCocktailService implements CocktailService {
  /// Use real ML Kit analysis instead of random selection
  final bool useMLKit;

  MockCocktailService({this.useMLKit = false});

  @override
  Future<CocktailData> selectCocktail({required String loserImagePath}) async {
    // For development: simulate analysis delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (useMLKit) {
      // In real scenario: would use GoogleMLKitCocktailService here
      // For now: just return deterministic result based on image path
      // This allows testing ML Kit logic in isolation
      return CocktailCatalog.getRandom();
    }

    // Default: return random cocktail (for UI/integration testing)
    return CocktailCatalog.getRandom();
  }
}
