# Consolidated Known Issues

This is the watertight gap log across all three codebases. Every row links back to the per-codebase known-issues file that has the full detail and remediation.

| ID | Codebase | Severity | Issue | Detail |
|---|---|---|---|---|
| **E-1** | ESP32-C3 | Blocker | `sendBLE` / `listenBLE` are empty stubs — no NUS implementation. | [esp32-c3/known-issues.md §1](../esp32-c3/known-issues.md#1-ble-stack-is-not-implemented) |
| **E-2** | ESP32-C3 | Blocker | `listenBTNround` multiple defects (B4/B5 typos, inverted loop guard, inverted assignment guard, stale `lastBx` updates, inconsistent debounce). | [esp32-c3/known-issues.md §2](../esp32-c3/known-issues.md#2-listenbtnroundint-i--multiple-defects-lines-114174) |
| **E-3** | ESP32-C3 | Hazard | `listenCMD()` blocks forever (no UART timeout). | [esp32-c3/known-issues.md §3](../esp32-c3/known-issues.md#3-listencmd-blocks-forever-lines-4951) |
| **E-4** | ESP32-C3 | Hazard | `btnTest()` is dead code, duplicated body, partial `lastBx` updates. | [esp32-c3/known-issues.md §4](../esp32-c3/known-issues.md#4-dead-btntest-lines-182263) |
| **E-5** | ESP32-C3 | Hazard | B6–B9 wired with pull-ups but unused; may be reserved for manual-pump feature. | [esp32-c3/known-issues.md §5](../esp32-c3/known-issues.md#5-b6b9-never-sampled-by-the-game-logic) |
| **N-1** | Arduino Nano | Hazard | `#define B0 8` collides with `SoftwareSerial(8, 9)` RX. | [arduino-nano/known-issues.md §1](../arduino-nano/known-issues.md#1-define-b0-8-collides-with-softwareserial-rx) |
| **N-2** | Arduino Nano | Hazard | `Adafruit_VL53L0X` declared in `lib_deps` but never `#include`d. | [arduino-nano/known-issues.md §2](../arduino-nano/known-issues.md#2-adafruit_vl53l0x-library-declared-but-unused) |
| **N-3** | Arduino Nano | Hazard | `// TODO: add logic for manual pumping` — feature not implemented. | [arduino-nano/known-issues.md §3](../arduino-nano/known-issues.md#3-manual-pump-feature-is-a-todo) |
| **N-4** | Arduino Nano | Hazard | No NAK on malformed `mix_*`; ESP-side `listenCMD` will hang. | [arduino-nano/known-issues.md §4](../arduino-nano/known-issues.md#4-no-nak-on-malformed-mix_) |
| **N-5** | Arduino Nano | Hazard | Pumps run blocking via `delay()`; no abort. | [arduino-nano/known-issues.md §5](../arduino-nano/known-issues.md#5-pumps-run-blocking-in-sequence) |
| **F-1** | Flutter | Blocker | Cocktail-id ↔ drink-id drift: every ML pick falls through `_mapCocktailToDrink`'s default arm and always pours Tropical Chaos. | [frontend/known-issues.md F-1](../frontend/known-issues.md#f-1-cocktail-id--drink-id-drift-makes-ml-pipeline-ineffective) |
| **F-2** | Flutter | Cosmetic | `MockDrinkService` is misnamed — it's the production implementation. | [frontend/known-issues.md F-2](../frontend/known-issues.md#f-2-mockdrinkservice-is-misnamed) |
| **F-3** | Flutter | Cosmetic | Unnecessary `(widget.drinkService as dynamic)` cast in `GameScreen._selectDrink`. | [frontend/known-issues.md F-3](../frontend/known-issues.md#f-3-unnecessary-dynamic-cast-in-gamescreen) |
| **F-4** | Flutter | Cosmetic | Dead local enums/classes in `RecipesPage`. | [frontend/known-issues.md F-4](../frontend/known-issues.md#f-4-dead-local-types-in-recipespage) |
| **F-5** | Flutter | Design gap | Recipes feature browse-only, not wired to mixer. | [frontend/known-issues.md F-5](../frontend/known-issues.md#f-5-recipes-feature-not-wired-to-the-mixer) |
| **F-6** | Flutter | Hazard | BLE disconnect mid-game: 60 s `waitForMessage` timeout, no UI feedback. | [frontend/known-issues.md F-6](../frontend/known-issues.md#f-6-ble-disconnect-during-game-leaves-ui-stuck) |
| **F-7** | Flutter | Cosmetic | `MockCocktailService.useMLKit` flag has no effect. | [frontend/known-issues.md F-7](../frontend/known-issues.md#f-7-mockcocktailserviceusemlkit-flag-has-no-effect) |
| **F-8** | Flutter | Debt | No tests under `code/frontend/test/`. | [frontend/known-issues.md F-8](../frontend/known-issues.md#f-8-no-automatic-tests) |
| **F-9** | Flutter | Debt | All UI strings hardcoded German; no i18n. | [frontend/known-issues.md F-9](../frontend/known-issues.md#f-9-all-ui-strings-hardcoded-in-german) |
| **F-10** | Flutter | Debt | Pre-existing `flutter analyze` warnings — see [`analysis_result.md`](../../code/frontend/analysis_result.md). | [frontend/known-issues.md F-10](../frontend/known-issues.md#f-10-flutter-analyze-still-surfaces-minor-warnings) |

## Severity definitions

- **Blocker** — feature does not work end-to-end today.
- **Hazard** — works in the happy path but will misbehave under real failure modes, or is a latent footgun.
- **Cosmetic** — code-quality drift, no runtime impact.
- **Design gap** — feature intentionally incomplete.
- **Debt** — long-tail maintenance work.

## Cross-codebase interactions worth highlighting

These are issues whose impact spans the wire — fix on one side, the other side breaks differently:

- **E-1 + F-6** — until the ESP has a working BLE stack, the app's connectionStream stays `false` and never even attempts a game; once it does, F-6 becomes the next failure mode if the link drops mid-game.
- **E-3 + N-4** — the Nano never NAKs malformed mix orders, and the ESP `listenCMD` has no timeout, so a single bad pump request from the app would hang both firmwares until power-cycle. The Flutter app's 60-second BLE timeout (F-6 again) is the only existing safety net.
- **E-2 + protocol** — `listenBTNround` is the only place the ESP can produce a `runde_*` message. Until it is fixed, the entire round/series flow is dead even with the BLE stack ported.
- **F-1 + recipe calibration** — the cocktail-id mismatch means the calibration table in `MockDrinkService._drinks` is never actually used (everything falls into `_drinks[0]`). Touching the four drink ids is therefore safe today *and* dangerous tomorrow: as soon as F-1 is fixed, those ids become live calibration data.

## Resolution dependency order (recommended)

1. **F-1** (one-line fix in `drink_service.dart`) — unblocks the ML pipeline for any subsequent end-to-end test.
2. **E-1** — port the NUS skeleton from `code/frontend/README.md` into the ESP firmware.
3. **E-2** — rewrite `listenBTNround` once the BLE path works.
4. **E-3** + **N-4** — add timeouts and a `mix_err` frame so a bad order doesn't lock the system.
5. **F-6** — wire `connectionStream` into the game flow to react to mid-game drops.
6. Cosmetic and debt items (**E-4, E-5, N-1, N-2, N-3, N-5, F-2, F-3, F-4, F-5, F-7, F-8, F-9, F-10**) — clean up alongside the above as they cross paths.
