# Frontend — ML pipeline (loser → cocktail)

Two services and one data class, all under [`code/frontend/lib/services/`](../../code/frontend/lib/services/):

1. [`image_analyzer_service.dart`](../../code/frontend/lib/services/image_analyzer_service.dart) — wraps Google ML Kit's face detector and image labeler. Produces an `ImageProfile`.
2. [`google_ml_kit_cocktail_service.dart`](../../code/frontend/lib/services/google_ml_kit_cocktail_service.dart) — turns the profile into per-tag **mood weights**, then scores each candidate cocktail by its tags and picks the highest.
3. [`drink_service.dart`](../../code/frontend/lib/services/drink_service.dart) `MockDrinkService` — supplies the candidate pool (generated cocktails, or the fallback catalog) and turns the chosen cocktail into a physical `Drink`.

Key change from the earlier design: the matcher no longer scores four fixed cocktails with four bespoke `_score*` methods. It scores **whatever pool it is handed** — normally the AI-generated cocktails from the current pump setup — using a single generic tag-weight scorer, so it works with any cocktail set.

End-to-end:

```
loser image path
   │
   ▼   ImageAnalyzerService.analyzeImage
ImageProfile {face?, smile, eyes, head Y/Z, top-10 labels}
   │
   ▼   GoogleMLKitCocktailService.selectCocktail(candidates: pool)
_moodWeights(profile)  →  _scoreByTags(candidate.pairingTags)  →  arg-max
   │
   ▼   MockDrinkService: chosen GeneratedCocktail.toDrink()  (or fallback catalog → _mapCocktailToDrink)
Drink {pumpAmounts: [a,b,c,d]}
   │
   ▼   BleMixerService.orderDrink
"mix_a_b_c_d"  on BLE
```

## `ImageProfile`

```dart
class ImageProfile {
  final bool faceDetected;
  final double? estimatedSmile;          // 0..1
  final double? estimatedLeftEyeOpen;    // 0..1
  final double? estimatedRightEyeOpen;   // 0..1
  final double? headEulerAngleY;         // degrees, left/right
  final double? headEulerAngleZ;         // degrees, tilt
  final List<String> labels;             // top-N image labels (lowercased on use)
}
```

Derived properties:

| Getter | Definition |
|---|---|
| `isSmiling` | `estimatedSmile != null && estimatedSmile! > 0.4` |
| `isNeutralOrSad` | `!isSmiling` |
| `emotion` | `> 0.6 → 'happy'`, `> 0.3 → 'neutral'`, else `'sad'`; `'unknown'` if `estimatedSmile` is null |

### `ImageAnalyzerService`

```dart
await analyzer.initialize();                     // idempotent
final profile = await analyzer.analyzeImage(path);
await analyzer.dispose();                         // closes both detectors
```

`FaceDetector`: `performanceMode: accurate`, landmarks on, classification on. `ImageLabeler`: default options. `analyzeImage`:

1. No face → `ImageProfile(faceDetected: false, labels: <top-5 labels>)`.
2. Otherwise first face (`faces.first`) + top-10 labels.
3. On any exception → `ImageProfile(faceDetected: false)`, logged via `debugPrint`.

## `GoogleMLKitCocktailService` — mood-weight matcher

`selectCocktail({loserImagePath, candidates})`:

1. `assert(candidates.isNotEmpty)`. If `candidates.length == 1`, return it immediately (no analysis).
2. `analyzer.initialize()` + `analyzeImage(loserImagePath)`.
3. If `!faceDetected` → random candidate.
4. Otherwise build `_moodWeights(profile)`, score every candidate with `_scoreByTags`, return the arg-max.
5. Any exception → random candidate (logged).

### `_moodWeights(profile)` → `Map<String, double>`

Accumulates weights per mood tag from four signal groups (all tags are from [`kMoodTags`](../../code/frontend/lib/models/mood_tags.dart)):

| Signal | Condition | Tags boosted (+weight) |
|---|---|---|
| Emotion | `emotion == 'happy'` | happy, fresh, light, colorful, playful, young (+0.5 each) |
| Emotion | `emotion == 'neutral'` | sophisticated, calm, warm, classic, traditional (+0.4) |
| Emotion | `emotion == 'sad'` | dark, serious, mysterious, intense, complex (+0.4) |
| Eye openness | `avgEyeOpen > 0.7` (default 0.5) | energetic, bold, adventurous (+0.3) |
| Head pose | `|headEulerAngleY| > 15` or `|headEulerAngleZ| > 10` | confident, bold, adventurous, intense (+0.25) |
| Image labels | label contains a key (e.g. `tropical`, `green`, `blue`, `orange`, `red`, `yellow`, `dark`, `wood`, `bright`) | that key's mapped tags (+0.3) |

### `_scoreByTags(tags, weights)`

```dart
score = Σ over candidate.pairingTags of (weights[tag] ?? 0.0) + 0.01
```

The `+0.01` base per tag keeps scores stable (and slightly favours tag-richer cocktails) when the profile emphasises none of a candidate's tags. `_labelsContain` lowercases everything and uses `String.contains`, so `"Tropical Rainforest"` matches `tropical`.

These weights are **hand-picked, not learned**. To retune, edit `_moodWeights` / `_scoreByTags` directly — there is no config file. Because scoring is tag-based and pool-agnostic, adding cocktails needs no matcher change, as long as their tags come from `kMoodTags` (tags outside it contribute only the +0.01 base).

## From cocktail to pump amounts

Two paths, both in `MockDrinkService.selectDrinkWithCocktail` (see [services.md](services.md)):

- **Generated pool (primary):** the chosen `GeneratedCocktail` already carries its own `pumpAmounts`; `toDrink()` passes them straight through. No id mapping, no unit conversion.
- **Fallback catalog:** when no pool exists, the chosen `CocktailData` id is mapped to a calibration `Drink` by `_mapCocktailToDrink` (`long_island → tropical_chaos`, `old_fashioned → sour_loser`, `mojito → blue_regret`, `zombie → bitter_defeat`). The switch arms match the catalog ids, so each catalog cocktail pours its intended calibration recipe (this was the ex-F-1 bug, now fixed).

## Where the candidate pool comes from

The pool the matcher scores is generated up front from the user's four pump ingredients — see the recipe-generation subsystem in [services.md](services.md) (`RecipeStore` + `RecipeGeneratorService` / Gemma). The generators are constrained to emit only `kMoodTags`, precisely so this matcher can score them. Keep [`mood_tags.dart`](../../code/frontend/lib/models/mood_tags.dart), the generator prompts, and the tag keys in `_moodWeights` in sync.

## Testing

[`test/services/cocktail_selection_test.dart`](../../code/frontend/test/services/cocktail_selection_test.dart) drives the matcher with a `_FakeAnalyzer` (fixed `ImageProfile`, no native ML Kit): a happy face favours fresh/happy-tagged candidates, a single-candidate pool is returned without analysis, and both the ML-Kit and mock services pick from the provided pool.
