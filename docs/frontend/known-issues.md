# Frontend — Known issues

Reference for the consolidated cross-codebase list: [`../cross-dependencies/known-issues.md`](../cross-dependencies/known-issues.md). The pre-existing analysis report at [`code/frontend/analysis_result.md`](../../code/frontend/analysis_result.md) covers most of what is listed here; this page summarises and adds severity.

## Blockers — visible end-user bug

### F-1. Cocktail-id ↔ drink-id drift makes ML pipeline ineffective

`GoogleMLKitCocktailService` returns a `CocktailData` whose id comes from [`cocktail_catalog.dart`](../../code/frontend/lib/data/cocktail_catalog.dart) — i.e. one of `long_island`, `old_fashioned`, `mojito`, `zombie`. `MockDrinkService._mapCocktailToDrink` in [`drink_service.dart`](../../code/frontend/lib/services/drink_service.dart) switches on different ids — `tropical_chaos`, `sour_loser`, `blue_regret`, `bitter_defeat`. Every real run therefore falls through the `_ => _drinks[0]` default, and the mixer always pours Tropical Chaos `[30, 20, 10, 40]`.

**Fix options** (pick one):

- Change `_mapCocktailToDrink` arms to the catalog ids.
- Rename the `_drinks` entries so their ids match the catalog.
- Make the mapping data-driven (e.g. a `Map<String, Drink>` declared next to the catalog).

## Hazards — won't crash but degrade quality

### F-2. `MockDrinkService` is misnamed

[`drink_service.dart:32`](../../code/frontend/lib/services/drink_service.dart) — this is the only production `DrinkService`. There is no "real" version to swap in. The name causes test/prod confusion. Suggested rename: `MlKitDrinkService` or `DefaultDrinkService`. `MockMixerService` (the in-memory mock) and `MockCocktailService` are correctly named.

### F-3. Unnecessary dynamic cast in `GameScreen`

[`game_screen.dart:109`](../../code/frontend/lib/features/game/game_screen.dart):

```dart
final selection = await (widget.drinkService as dynamic)
    .selectDrinkWithCocktail(loserPlayer: loser, loserImagePath: loserPath);
```

`selectDrinkWithCocktail` is declared on the `DrinkService` interface — the cast loses static type checking for no reason. Drop the `as dynamic`.

### F-4. Dead local types in `RecipesPage`

[`recipes_page.dart`](../../code/frontend/lib/features/recipes/recipes_page.dart) declares `_RecipeFilter`, `_RecipeStatus`, `_RecipeItem` privately, while [`recipe_models.dart`](../../code/frontend/lib/features/recipes/models/recipe_models.dart) holds the public versions actually used. The locals are unused. Remove.

### F-5. Recipes feature not wired to the mixer

[`recipes_page.dart`](../../code/frontend/lib/features/recipes/recipes_page.dart) is browse-only; no path lets a user pour one of the recipes. Either wire it through `BleMixerService` or document it explicitly as a design preview.

### F-6. BLE disconnect during game leaves UI stuck

If the BLE link drops while `BleBackendService.getRoundResult` or `BleMixerService.orderDrink` is waiting, `BleService.waitForMessage` waits the full 60-second default before throwing. The game screen has no visible reaction during that window. Surface a banner when `connectionStream` emits `false` mid-game and abort the futures early.

### F-7. `MockCocktailService.useMLKit` flag has no effect

[`mock_cocktail_service.dart`](../../code/frontend/lib/services/mock_cocktail_service.dart) returns `CocktailCatalog.getRandom()` regardless of the flag (lines 18–22). Either remove the flag or actually delegate to `GoogleMLKitCocktailService` when `true`.

## Cosmetic / debt

### F-8. No automatic tests

`code/frontend/test/` is empty. `Gesture.versus`, `RoundResult.winner`, the `_seriesWinner` getter, and the four `_score*` methods are pure functions and trivially testable.

### F-9. All UI strings hardcoded in German

No `flutter_localizations` / `intl` setup. Acceptable for the current product, but worth flagging for any future translation request.

### F-10. `flutter analyze` still surfaces minor warnings

See [`analysis_result.md`](../../code/frontend/analysis_result.md) for the full list. None are blockers.

## Action checklist for "feature complete" frontend

- [ ] **F-1** — fix the cocktail-id ↔ drink-id mismatch (highest priority — currently breaks the ML feature end-to-end).
- [ ] **F-2** — rename `MockDrinkService`.
- [ ] **F-3** — drop the `as dynamic` cast.
- [ ] **F-4** — delete dead `_RecipeFilter` / `_RecipeStatus` / `_RecipeItem`.
- [ ] **F-6** — wire `BleService.connectionStream` into the game flow to break out of stale waits.
- [ ] **F-8** — add tests for the pure logic; the gesture-versus matrix is a one-liner.
- [ ] **F-5, F-7, F-9, F-10** — product calls; defer or fix as scope allows.
