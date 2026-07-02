# Frontend — Known issues

Reference for the consolidated cross-codebase list: [`../cross-dependencies/known-issues.md`](../cross-dependencies/known-issues.md). The pre-existing analysis report at [`code/frontend/analysis_result.md`](../../code/frontend/analysis_result.md) predates the recipe-generation rework — treat it as historical.

## Open

### F-2. `MockDrinkService` is misnamed

[`drink_service.dart`](../../code/frontend/lib/services/drink_service.dart) — this is the production `DrinkService` (it drives the real ML matcher and the generated pool). The `Mock` prefix causes test/prod confusion; there is no "real" version to swap in. Suggested rename: `DefaultDrinkService` / `RecipePoolDrinkService`. (`MockMixerService`, `MockCocktailService`, `MockRecipeGeneratorService` *are* genuine mocks — correctly named.)

### F-3. Unnecessary dynamic cast in `GameScreen`

[`game_screen.dart` `_selectDrink`](../../code/frontend/lib/features/game/game_screen.dart):

```dart
final selection = await (widget.drinkService as dynamic)
    .selectDrinkWithCocktail(loserPlayer: loser, loserImagePath: loserPath);
```

`selectDrinkWithCocktail` is declared on the `DrinkService` interface — the cast loses static type checking for no reason. Drop the `as dynamic`.

### F-11. Duplicated, unreachable draw-check block in `_playRound`

[`game_screen.dart`](../../code/frontend/lib/features/game/game_screen.dart) contains two identical `if (result.winner == null) { … _playRound(); return; }` blocks back to back. The first one always returns, so the second is dead code. Delete the duplicate.

### F-9. All UI strings hardcoded in German

No `flutter_localizations` / `intl` setup. Acceptable for the current product; flag for any future translation request. (Note the Gemma prompt and system instruction are also German by design.)

### F-10. `flutter analyze` may still surface minor warnings

Run `flutter analyze` for the current list; [`analysis_result.md`](../../code/frontend/analysis_result.md) is a historical snapshot from before the rework. None are known blockers.

## Cross-codebase

### X-1. The app never sends `stop`

`BleBackendService.getRoundResult` sends `runde_ok` after every round and never sends `stop`, but the ESP round loop only ends the series on `stop` (or a timeout). Fix on the app side by sending `stop` once `_seriesWinner != null`. Full detail in [`../cross-dependencies/known-issues.md` X-1](../cross-dependencies/known-issues.md).

## Resolved

| ID | Was | Now |
|---|---|---|
| **F-1** | Cocktail-id ↔ drink-id drift always poured Tropical Chaos. | The generated-pool path uses each `GeneratedCocktail`'s own `pumpAmounts` (no mapping), and the fallback `_mapCocktailToDrink` arms now match the catalog ids (`long_island`/`old_fashioned`/`mojito`/`zombie`). |
| **F-4** | Dead local enums/classes in `RecipesPage`. | `RecipesPage` rewritten around `RecipeStore`; the dead `_RecipeFilter`/`_RecipeStatus`/`_RecipeItem` and the old recipe-catalog files are gone. |
| **F-5** | Recipes browse-only, not wired to the mixer. | The generated pool now drives the loser's drink in the game and the home-screen MIX RANDOM DRINK button. |
| **F-6** | BLE disconnect mid-game hung on a 60 s timeout with no feedback. | `GameScreen` refuses to start when disconnected, watches `connectionStream`, and aborts every BLE wait with a SnackBar + pop to home. |
| **F-7** | `MockCocktailService.useMLKit` flag had no effect. | Flag removed; `MockCocktailService.selectCocktail` picks from the passed candidate pool (throws if empty). |
| **F-8** | No automated tests. | `test/services/` now covers the parser/sanitizer, the mock generator, the recipe store (persistence + invalidation), and cocktail selection; `test/widget_test.dart` covers `PumpSetup`/`GeneratedCocktail`. |

## Action checklist

- [ ] **F-2** — rename `MockDrinkService`.
- [ ] **F-3** — drop the `as dynamic` cast.
- [ ] **F-11** — remove the duplicated draw-check block.
- [ ] **X-1** — send `stop` at series end so the ESP loop terminates cleanly.
- [ ] **F-9, F-10** — product/maintenance calls; defer or fix as scope allows.
