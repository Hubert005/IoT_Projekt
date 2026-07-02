# Consolidated Known Issues

This is the watertight gap log across all three codebases. Every row links back to the per-codebase known-issues file that has the full detail and remediation.

## Open issues

| ID | Codebase | Severity | Issue | Detail |
|---|---|---|---|---|
| **E-1** | ESP32-C3 | Blocker | `sendBLE` / `listenBLE` are empty stubs — no NUS implementation. | [esp32-c3/known-issues.md §1](../esp32-c3/known-issues.md#1-ble-stack-is-not-implemented) |
| **E-6** | ESP32-C3 | Blocker | `listenBLEBlocking(30000)` is called in `loop()` but never defined — firmware does not compile as committed. | [esp32-c3/known-issues.md §6](../esp32-c3/known-issues.md) |
| **E-2** | ESP32-C3 | Blocker | `listenBTNround` multiple defects (B4/B5 typos, inverted loop guard, inverted assignment guard, stale `lastBx`, inconsistent debounce). | [esp32-c3/known-issues.md §2](../esp32-c3/known-issues.md) |
| **E-3** | ESP32-C3 | Hazard | Mix-relay error paths swallowed: `listenCMD` now has a 20 s timeout, but a `mix_err` NAK or a timeout is never relayed to the app. | [esp32-c3/known-issues.md §3](../esp32-c3/known-issues.md) |
| **E-4** | ESP32-C3 | Cosmetic | `btnTest()` is dead code, duplicated body, partial `lastBx` updates. | [esp32-c3/known-issues.md §4](../esp32-c3/known-issues.md) |
| **E-5** | ESP32-C3 | Hazard | B6–B9 wired with pull-ups but unused; may be reserved for manual-pump feature. | [esp32-c3/known-issues.md §5](../esp32-c3/known-issues.md) |
| **E-7** | ESP32-C3 | Cosmetic | `Serial1.begin` called twice in `setup()`. | [esp32-c3/known-issues.md §7](../esp32-c3/known-issues.md) |
| **N-1** | Arduino Nano | Hazard | `#define B0 8` collides with `SoftwareSerial(8, 9)` RX. | [arduino-nano/known-issues.md §1](../arduino-nano/known-issues.md) |
| **N-2** | Arduino Nano | Cosmetic | `Adafruit_VL53L0X` (and `Wire.h`) declared/included but unused. | [arduino-nano/known-issues.md §2](../arduino-nano/known-issues.md) |
| **N-3** | Arduino Nano | Design gap | `// TODO: add logic for manual pumping` — feature not implemented. | [arduino-nano/known-issues.md §3](../arduino-nano/known-issues.md) |
| **N-5** | Arduino Nano | Hazard | Pumps run blocking via `delay()`; no abort. | [arduino-nano/known-issues.md §5](../arduino-nano/known-issues.md) |
| **X-1** | Cross (ESP ↔ app) | Hazard | The ESP's round loop expects a `stop` frame to end the series, but the app never sends one (it only sends `runde_ok`). See below. | this file |
| **F-2** | Flutter | Cosmetic | `MockDrinkService` is misnamed — it's the production implementation. | [frontend/known-issues.md F-2](../frontend/known-issues.md) |
| **F-3** | Flutter | Cosmetic | Unnecessary `(widget.drinkService as dynamic)` cast in `GameScreen._selectDrink`. | [frontend/known-issues.md F-3](../frontend/known-issues.md) |
| **F-11** | Flutter | Cosmetic | Duplicated, unreachable draw-check block in `GameScreen._playRound`. | [frontend/known-issues.md F-11](../frontend/known-issues.md) |
| **F-9** | Flutter | Debt | All UI strings hardcoded German; no i18n. | [frontend/known-issues.md F-9](../frontend/known-issues.md) |
| **F-10** | Flutter | Debt | Pre-existing `flutter analyze` warnings — see [`analysis_result.md`](../../code/frontend/analysis_result.md). | [frontend/known-issues.md F-10](../frontend/known-issues.md) |

## Resolved since the docs were first written

| ID | Was | Now |
|---|---|---|
| **N-4** | No NAK on malformed `mix_*`; ESP would hang. | Nano emits `mix_err` on parse failure ([arduino-nano/known-issues.md §4](../arduino-nano/known-issues.md)). (ESP still doesn't relay it — tracked as E-3.) |
| **F-1** | Cocktail-id ↔ drink-id drift always poured Tropical Chaos. | `_mapCocktailToDrink` arms now match the catalog ids, and the generated-pool path bypasses the mapping entirely ([frontend/known-issues.md](../frontend/known-issues.md#resolved)). |
| **F-4** | Dead local enums/classes in `RecipesPage`. | `RecipesPage` rewritten around the recipe generator; dead types gone. |
| **F-5** | Recipes feature browse-only, not wired to mixer. | Generated recipes now drive the loser's drink and the home-screen "MIX RANDOM DRINK" button. |
| **F-6** | BLE disconnect mid-game hung on a 60 s timeout with no feedback. | `GameScreen` watches `connectionStream` and aborts with a SnackBar + pop to home. |
| **F-7** | `MockCocktailService.useMLKit` flag had no effect. | Flag removed; `MockCocktailService` picks from the candidate pool. |
| **F-8** | No automated tests. | `test/` now has parser, generator, store, and cocktail-selection suites. |

## Severity definitions

- **Blocker** — feature does not work end-to-end today (or does not build).
- **Hazard** — works in the happy path but will misbehave under real failure modes, or is a latent footgun.
- **Cosmetic** — code-quality drift, no runtime impact.
- **Design gap** — feature intentionally incomplete.
- **Debt** — long-tail maintenance work.

## Cross-codebase interactions worth highlighting

- **X-1 (the `stop` gap)** — the ESP round loop (`code_esp32-c3/src/main.cpp:95-106`) breaks only on `stop` or an empty read; the app (`ble_backend_service.dart`) sends `runde_ok` after every round and never `stop`. Once E-1/E-6/E-2 are fixed and the game actually runs, the ESP would collect a phantom extra round after the series ends. Fix by having the app send `stop` when `_seriesWinner != null`, or by moving the round-count decision back into the firmware.
- **E-1 + E-6** — the BLE stack is unimplemented *and* the game loop calls an undefined function, so the ESP neither talks BLE nor compiles. Both must land before any end-to-end test.
- **E-3 + N-4** — the Nano now NAKs malformed mix orders with `mix_err`, and the ESP's `listenCMD` has a 20 s timeout, so a bad order no longer hangs both firmwares. But the ESP still doesn't forward `mix_err`/timeout to the app, so the app relies on its own BLE timeout (now backed by the mid-game abort, ex-F-6).
- **E-2 + protocol** — `listenBTNround` is the only place the ESP can produce a `runde_*` message. Until it is fixed, the entire round/series flow is dead even with the BLE stack ported.

## Resolution dependency order (recommended)

1. **E-1 + E-6** — port the NUS skeleton from `code/frontend/README.md` and implement (or remove) `listenBLEBlocking` so the firmware builds and talks BLE.
2. **E-2** — rewrite `listenBTNround` once the BLE path works.
3. **X-1** — make the app send `stop` at series end (or restructure the round-count ownership).
4. **E-3** — relay `mix_err` / relay-timeout to the app so a bad order surfaces immediately.
5. Cosmetic and debt items (**E-4, E-5, E-7, N-1, N-2, N-3, N-5, F-2, F-3, F-11, F-9, F-10**) — clean up alongside the above as they cross paths.
