/// Canonical mood-tag vocabulary understood by the selfie matcher
/// ([GoogleMLKitCocktailService._moodWeights]). Both the mock generator and the
/// LLM-backed generator must only emit tags from this list, otherwise the
/// image-based cocktail pairing silently scores them as 0.
///
/// Keep this in sync with the tags referenced in
/// `services/google_ml_kit_cocktail_service.dart`.
const List<String> kMoodTags = [
  'happy',
  'fresh',
  'light',
  'colorful',
  'playful',
  'young',
  'sophisticated',
  'calm',
  'warm',
  'classic',
  'traditional',
  'dark',
  'serious',
  'mysterious',
  'intense',
  'complex',
  'energetic',
  'bold',
  'adventurous',
  'confident',
  'tropical',
];
