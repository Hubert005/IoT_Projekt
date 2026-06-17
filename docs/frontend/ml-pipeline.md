# Frontend — ML pipeline (loser → cocktail)

Two services and one data class, all under [`code/frontend/lib/services/`](../../code/frontend/lib/services/):

1. [`image_analyzer_service.dart`](../../code/frontend/lib/services/image_analyzer_service.dart) — wraps Google ML Kit's face detector and image labeler. Produces an `ImageProfile`.
2. [`google_ml_kit_cocktail_service.dart`](../../code/frontend/lib/services/google_ml_kit_cocktail_service.dart) — applies four hand-tuned heuristics to score the four catalog cocktails, picks the highest.
3. [`drink_service.dart`](../../code/frontend/lib/services/drink_service.dart) `MockDrinkService._mapCocktailToDrink` — translates the cocktail id to a physical `Drink` (`pumpAmounts`).

End-to-end:

```
loser image path
   │
   ▼   ImageAnalyzerService.analyzeImage
ImageProfile {face?, smile, eyes, head Y/Z, top-10 labels}
   │
   ▼   GoogleMLKitCocktailService.selectCocktail
{long_island | old_fashioned | mojito | zombie}.score → arg-max
   │
   ▼   MockDrinkService._mapCocktailToDrink
Drink {id, pumpAmounts: [a,b,c,d]}
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
// ...
await analyzer.dispose();                        // closes both detectors
```

`FaceDetector` is configured with `performanceMode: accurate`, landmarks on, classification on. `ImageLabeler` uses default options. `analyzeImage`:

1. If no face: returns `ImageProfile(faceDetected: false, labels: <top-5 labels>)`.
2. Otherwise uses the first face (`faces.first`) and the top-10 labels.
3. On any exception, returns `ImageProfile(faceDetected: false)` and logs via `debugPrint`.

## `GoogleMLKitCocktailService` scoring heuristics

The service calls `analyzer.initialize()` then `analyzer.analyzeImage(loserImagePath)`. If `!profile.faceDetected`, it falls back to `CocktailCatalog.getRandom()`. Otherwise it scores all four cocktails and returns the highest. Errors caught at the top of the method route to a random fallback.

Score components per cocktail (values from the source, summed; no normalisation):

### `long_island` — confident, energetic, complex

| Trigger | Adds |
|---|---|
| `emotion == 'neutral'` or `'sad'` | +0.3 |
| \|`headEulerAngleY`\| > 15° | +0.2 |
| Any label contains one of `dark`, `serious`, `intense`, `bold` | +0.3 |
| `avgEyeOpen` (left/right mean, default 0.5) | + `avgEyeOpen * 0.2` |

Max realistic: ~0.8.

### `old_fashioned` — sophisticated, calm, warm

| Trigger | Adds |
|---|---|
| `emotion == 'neutral'` | +0.4 |
| Any label contains one of `warm`, `brown`, `vintage`, `classic`, `wood` | +0.3 |
| \|`headEulerAngleZ`\| < 10° | +0.2 |
| `0.2 < estimatedSmile < 0.5` | +0.2 |

Max realistic: ~1.1.

### `mojito` — happy, fresh, light

| Trigger | Adds |
|---|---|
| `emotion == 'happy'` | +0.5 |
| Any label contains one of `light`, `green`, `blue`, `fresh`, `colorful`, `bright`, `young` | +0.3 |
| `avgEyeOpen` > 0.7 | +0.2 |
| \|`headEulerAngleY`\| < 20° | +0.1 |

Max realistic: ~1.1.

### `zombie` — adventurous, bold, tropical

| Trigger | Adds |
|---|---|
| `emotion == 'happy'` | +0.25 |
| else if `emotion == 'sad'` or `'neutral'` | +0.2 |
| Any label contains one of `tropical`, `exotic`, `colorful`, `orange`, `red`, `yellow` | +0.35 |
| \|`headEulerAngleY`\| > 10° | +0.15 |
| \|`headEulerAngleZ`\| > 8° | +0.15 |

Max realistic: ~0.9.

These weights are **hand-picked, not learned**. If the catalog or theme changes, retune by editing the four `_score*` methods directly — there is no config file.

The `_labelsContain` helper lowercases everything and uses `String.contains`, so a label like `"Tropical Rainforest"` matches `"tropical"`.

## Cocktail → drink mapping

[`drink_service.dart`](../../code/frontend/lib/services/drink_service.dart) `_mapCocktailToDrink`:

```dart
switch (cocktail.id) {
  'tropical_chaos' => _drinks[0],
  'sour_loser'     => _drinks[1],
  'blue_regret'    => _drinks[2],
  'bitter_defeat'  => _drinks[3],
  _                => _drinks[0],       // silent default to tropical_chaos
}
```

But the catalog (see [services.md](services.md)) has different ids — `long_island`, `old_fashioned`, `mojito`, `zombie`. So today **every ML-chosen cocktail hits the default case** and the pumps always run the Tropical Chaos recipe. This drift is flagged in [known-issues.md](known-issues.md) — it is the highest-priority correctness bug in the ML pipeline.

## Tuning checklist

When a designer asks for a "softer" cocktail recommendation:

1. Adjust the relevant `_score*` thresholds in `google_ml_kit_cocktail_service.dart`.
2. If you add a cocktail, add a `CocktailData` row to `data/cocktail_catalog.dart`, a `Drink` to `MockDrinkService._drinks`, a switch arm to `_mapCocktailToDrink`, and a `_score<NewName>` method called from the `scores` map in `selectCocktail`.
3. Until the mapping bug is fixed (see [known-issues.md](known-issues.md)), `_mapCocktailToDrink` cases must match the catalog ids — not the `_drinks` ids.
