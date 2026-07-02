# Cross-Codebase Protocol — Single Source of Truth

This page defines the wire formats that connect the Flutter app, the ESP32-C3 firmware, and the Arduino Nano firmware. It supersedes the partial protocol notes in:

- [`kommunikationsablauf.md`](../../kommunikationsablauf.md) — the original German one-pager.
- [`code/frontend/README.md`](../../code/frontend/README.md) — the Flutter-side quick reference.

Both stay useful as quick reads, but if they ever drift from this file, **this file is authoritative**.

## Two wires, four endpoints

```
[Flutter app] <── BLE NUS ──> [ESP32-C3] <── SoftwareSerial 9600 8N1 ──> [Arduino Nano]
```

The ESP relays `mix_*` over UART and reports its own button presses over BLE. It also exchanges ack frames (`start_ok`, `runde_ok`, `stop`, `mix_ok`) with the app to gate the game flow.

## BLE — Nordic UART Service

| Role | UUID | Property |
|---|---|---|
| Service | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | — |
| RX char (app → ESP) | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | WRITE / WRITE_NR |
| TX char (ESP → app) | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | NOTIFY (CCCD enabled by app) |

> **Naming caveat:** the Dart source ([`ble_service.dart:15-17`](../../code/frontend/lib/services/ble_service.dart)) labels these from the **app's** viewpoint (`_txUuid = 6E400002` = the char the app *writes*; `_rxUuid = 6E400003` = the char the app *receives on*). This spec labels them from the **peripheral's** viewpoint (the ESP's "RX char" is the one it receives on = `6E400002`). Only the labels flip — the data directions are identical: `6E400002` always carries app→ESP, `6E400003` always carries ESP→app.

All payloads are ASCII strings terminated by `\n`. UTF-8 is overkill but tolerated.

### App → ESP (RX char)

| Message | Format | Sent when | ESP must |
|---|---|---|---|
| `start` | literal | User taps **START GAME** (via `GameScreen._init`) while connected. | Reply `start_ok`, then begin collecting round results. |
| `runde_ok` | literal | App finished rendering a round result, ready for the next one. | Move on to the next round. |
| `stop` | literal | *Intended:* app has decided the series is over (2-win majority or 3 rounds). | Leave the round loop and return to idle. |
| `mix_a_b_c_d` | four decimal integers, `_`-separated | App has chosen a drink and wants the pumps to run. | Drain stale UART bytes, forward verbatim to the Nano, wait for `mix_ok`, then notify the app with `mix_ok`. |

> ⚠️ **`stop` is expected by the ESP but never sent by the app.** The ESP's round loop exits only on `stop` or an empty read (timeout/disconnect); the Flutter side (`BleBackendService.getRoundResult`) sends `runde_ok` after *every* round, including the last, and never sends `stop`. So after the final round the ESP would `round++` and collect a phantom 4th round that nobody reads, while the app moves on to drink selection. This is an unresolved cross-codebase drift — see [known-issues.md](known-issues.md) X-1.

### ESP → App (TX char)

| Message | Format | Emitted when | Carries |
|---|---|---|---|
| `start_ok` | literal | Game accepted. | — |
| `runde_<i>_<g1>_<g2>` | `i ∈ {0,1,2}`, `g1`/`g2` ∈ {`0`,`1`,`2`} | After both players have pressed their gesture button for round `i`. | `i` = round index (ignored by the app); `g1`, `g2` = gestures. |
| `mix_ok` | literal | Nano signaled completion of `mix_*`. | — |

The Nano can also emit `mix_err` on the UART (malformed `mix_*`), but the ESP does **not** currently relay it to the app — see [known-issues.md](known-issues.md).

## UART — `Serial1` on the ESP (`Serial1.begin(9600, SERIAL_8N1, RXD1=21, TXD1=20)`) ↔ `SoftwareSerial(8, 9)` on the Nano

| Direction | Message | Source | Notes |
|---|---|---|---|
| ESP → Nano | `mix_a_b_c_d\n` | Forwarded verbatim from BLE in `sendCMD(msg)` ([`code_esp32-c3/src/main.cpp:112`](../../code/backend/code_esp32-c3/src/main.cpp)). | The ESP does not parse the body — opaque pass-through. |
| Nano → ESP | `mix_ok\n` | Emitted once all four pumps have run ([`code_arduino-nano/src/main.cpp:73`](../../code/backend/code_arduino-nano/src/main.cpp)). | Success ack. |
| Nano → ESP | `mix_err\n` | Emitted on malformed `mix_*` ([`code_arduino-nano/src/main.cpp:57`](../../code/backend/code_arduino-nano/src/main.cpp)). | NAK; read by the ESP's `listenCMD` (20 s timeout) but not relayed onward. |

Anything else on the UART is either USB-`Serial` debug (host-only) or, today, dead `btnTest()` test strings that the firmware never actually invokes (see [`../esp32-c3/known-issues.md`](../esp32-c3/known-issues.md) §4).

## Field semantics

### Round index

`i ∈ {0, 1, 2}`. The app's `GameScreen._currentRound` is 1-based internally and ignores the wire value — `BleBackendService.getRoundResult` discards `parts[1]` and tracks the round number itself.

### Gesture encoding

| Wire | Meaning |
|---|---|
| `0` | Rock     (✊) |
| `1` | Paper    (🖐) |
| `2` | Scissors (✌️) |

The `BleBackendService._parse` switch ([`ble_backend_service.dart:6`](../../code/frontend/lib/services/ble_backend_service.dart)) coerces any value other than `0` or `1` to `scissors`, so unexpected payloads degrade rather than crash.

### Pump amounts (`mix_a_b_c_d`)

| Field | Maps to | Unit |
|---|---|---|
| `a` | Pump 0 (Nano GPIO 2, M0) | ms FET-on time |
| `b` | Pump 1 (Nano GPIO 3, M1) | ms FET-on time |
| `c` | Pump 2 (Nano GPIO 4, M2) | ms FET-on time |
| `d` | Pump 3 (Nano GPIO 5, M3) | ms FET-on time |

The Nano runs the pumps **sequentially and blocking** ([`code_arduino-nano/src/main.cpp:68-70`](../../code/backend/code_arduino-nano/src/main.cpp)) — the wall-clock cost of a `mix_*` is `a + b + c + d` ms plus ~550 ms of buzzer beeps.

The four values come from a `Drink.pumpAmounts` list ([`drink.dart`](../../code/frontend/lib/models/drink.dart)). These are now supplied one of two ways:

- **Generated pool (primary):** cocktails generated from the user's four-ingredient pump setup ([`RecipeStore`](../../code/frontend/lib/services/recipe_store.dart)). Each generated cocktail carries its own `pumpAmounts` (per-pump ≤ 80, total ≤ 250). The value is passed to the wire verbatim — there is **no ml↔ms conversion**; the UI just labels it "ml".
- **Built-in calibration drinks (fallback):** four hard-coded `Drink`s in `MockDrinkService._drinks`, used only when no pool has been generated. See [`../frontend/services.md`](../frontend/services.md) for the current numbers.

## End-to-end recipe trace (`mix_30_20_10_40`)

| Stage | Where | What |
|---|---|---|
| 1 | [`MockDrinkService.selectDrinkWithCocktail`](../../code/frontend/lib/services/drink_service.dart) | Loser selfie → cocktail. If a generated pool exists, the chosen `GeneratedCocktail`'s own `pumpAmounts` are used; otherwise a built-in `Drink` (e.g. `[30, 20, 10, 40]`). |
| 2 | [`BleMixerService.orderDrink`](../../code/frontend/lib/services/ble_mixer_service.dart) | Builds the literal `"mix_30_20_10_40"`, calls `_ble.send(...)`. |
| 3 | `BleService.send` → NUS RX | UTF-8 bytes `mix_30_20_10_40\n` arrive at the ESP. |
| 4 | ESP `loop()` | `msg.startsWith("mix_")` matches; drains stale RX, calls `sendCMD(msg)` → `Serial1.println(msg)`. |
| 5 | Nano `loop()` | `espSerial.readStringUntil('\n')` returns the string; parser strips `mix_`, splits into `[30, 20, 10, 40]`. |
| 6 | Nano `pump()` loop | M0 high 30 ms, M1 high 20 ms, M2 high 10 ms, M3 high 40 ms (all blocking). |
| 7 | Nano | `espSerial.println("mix_ok")`, then 250/50/250 ms buzzer pattern. |
| 8 | ESP | `listenCMD()` returns `"mix_ok"`; ESP calls `sendBLE("mix_ok")`. |
| 9 | App | `BleMixerService.orderDrink` resolves; `GameScreen` flips `GamePhase.drinkSending → drinkReady`. |

## Timing budget

| Step | Approx | On the app's critical path? |
|---|---|---|
| BLE write (mix_30_20_10_40) | <20 ms | yes |
| ESP relay over UART (16 chars at 9600 baud) | ~17 ms | yes |
| Nano parse + pump loop (30 + 20 + 10 + 40 = 100 ms) | 100 ms | yes |
| Nano → ESP `mix_ok` (8 chars at 9600 baud) | ~8 ms | yes |
| ESP → app notify | <20 ms | yes |
| **Total app-perceived latency** | **~165 ms** | — |
| Buzzer pattern (250 + 50 + 250) | 550 ms | **no — runs after `mix_ok`** |

Crucial ordering: the Nano sends `mix_ok` (`main.cpp:73`) **before** it runs the buzzer (`main.cpp:76-82`). So the buzzer's 550 ms is *not* on the app's critical path — `BleMixerService.orderDrink` resolves and the UI reaches `drinkReady` while the buzzer is still beeping. The buzzer does, however, keep the Nano busy: it cannot accept a new `mix_*` for ~650 ms (100 ms pumping + 550 ms buzzer) after a command — see [`../arduino-nano/sequence-diagrams.md`](../arduino-nano/sequence-diagrams.md) §3.

The app's `waitForMessage('mix_ok')` defaults to a 60-second timeout. Since the frontend rework it is now backed up: `GameScreen` subscribes to `connectionStream` and **aborts** the game (visible SnackBar + pop to home) if the link drops mid-flight, rather than silently hanging (previously [known-issue F-6](../frontend/known-issues.md), now resolved).

## Encoding cheat-sheet

| Symbol | Type | Notes |
|---|---|---|
| `_` | field separator | literal underscore |
| `\n` | frame terminator | required on every wire |
| integer literal | decimal ASCII | no sign, no leading zeros required, no fixed width |

## Joint change checklist

Whenever you touch the protocol:

- [ ] Update both firmware sides (ESP32 and Nano `main.cpp`) if either parses the changed message.
- [ ] Update `BleService` / `BleBackendService` / `BleMixerService` on the Flutter side.
- [ ] Update [protocol.md](protocol.md) (this file).
- [ ] Update [sequence-diagrams.md](sequence-diagrams.md) if a new ordering is introduced.
- [ ] Update [`code/frontend/README.md`](../../code/frontend/README.md) so the user-facing summary still matches.
- [ ] Decide whether the original [`kommunikationsablauf.md`](../../kommunikationsablauf.md) should be archived or refreshed.
