# Cross-Codebase Protocol — Single Source of Truth

This page defines the wire formats that connect the Flutter app, the ESP32-C3 firmware, and the Arduino Nano firmware. It supersedes the partial protocol notes in:

- [`kommunikationsablauf.md`](../../kommunikationsablauf.md) — the original German one-pager.
- [`code/frontend/README.md`](../../code/frontend/README.md) — the Flutter-side quick reference.

Both stay useful as quick reads, but if they ever drift from this file, **this file is authoritative**.

## Two wires, four endpoints

```
[Flutter app] <── BLE NUS ──> [ESP32-C3] <── SoftwareSerial 9600 8N1 ──> [Arduino Nano]
```

The ESP relays `mix_*` over UART and reports its own button presses over BLE. It also exchanges ack frames (`runde_ok`, `mix_ok`, `start_ok`) with the app to gate the game flow.

## BLE — Nordic UART Service

| Role | UUID | Property |
|---|---|---|
| Service | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | — |
| RX char (app → ESP) | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | WRITE / WRITE_NR |
| TX char (ESP → app) | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | NOTIFY (CCCD enabled by app) |

All payloads are ASCII strings terminated by `\n`. UTF-8 is overkill but tolerated.

### App → ESP (RX char)

| Message | Format | Sent when | ESP must |
|---|---|---|---|
| `start` | literal | User taps **START GAME** in the app while connected. | Reply `start_ok`, then begin collecting round results. |
| `runde_ok` | literal | App finished rendering a round result, ready for the next one. | Move on to the next round (or finish the series). |
| `mix_a_b_c_d` | four decimal integers, `_`-separated | App has chosen the loser's drink and wants the pumps to run. | Forward verbatim to the Nano over UART, wait for `mix_ok` from the Nano, then notify the app with `mix_ok`. |

### ESP → App (TX char)

| Message | Format | Emitted when | Carries |
|---|---|---|---|
| `start_ok` | literal | Game accepted. | — |
| `runde_<i>_<g1>_<g2>` | `i ∈ {0,1,2}`, `g1`/`g2` ∈ {`0`,`1`,`2`} | After both players have pressed their gesture button for round `i`. | `i` = round index (0-based on the wire, 1-based in `GameScreen._currentRound`); `g1`, `g2` = gestures. |
| `mix_ok` | literal | Nano signaled completion of `mix_*`. | — |

## UART — `Serial1` on the ESP (`Serial1.begin(9600, SERIAL_8N1, RXD1=21, TXD1=20)`) ↔ `SoftwareSerial(8, 9)` on the Nano

| Direction | Message | Source | Notes |
|---|---|---|---|
| ESP → Nano | `mix_a_b_c_d\n` | Forwarded verbatim from BLE in `sendCMD(msg)` ([`code/backend/code_esp32-c3/src/main.cpp:99`](../../code/backend/code_esp32-c3/src/main.cpp)). | The ESP does not parse the body — it is opaque pass-through. |
| Nano → ESP | `mix_ok\n` | Emitted once all four pumps have run ([`code/backend/code_arduino-nano/src/main.cpp:69`](../../code/backend/code_arduino-nano/src/main.cpp)). | The Nano's only outbound `espSerial` message. |

Anything else on the UART is either USB-`Serial` debug (Nano → host) or, today, dead `btnTest()` test strings that the firmware never actually invokes (see [`../esp32-c3/known-issues.md`](../esp32-c3/known-issues.md) §4).

## Field semantics

### Round index

`i ∈ {0, 1, 2}`. Three rounds maximum per series. The app's `GameScreen._currentRound` is 1-based internally but ignores the wire value — `BleBackendService.getRoundResult` discards `parts[1]` and tracks the round number itself.

### Gesture encoding

| Wire | Meaning |
|---|---|
| `0` | Rock     (✊) |
| `1` | Paper    (🖐) |
| `2` | Scissors (✌️) |

The `BleBackendService._parse` switch ([`code/frontend/lib/services/ble_backend_service.dart:6`](../../code/frontend/lib/services/ble_backend_service.dart)) coerces any value other than `0` or `1` to `scissors`, so unexpected payloads degrade rather than crash.

### Pump amounts (`mix_a_b_c_d`)

| Field | Maps to | Unit |
|---|---|---|
| `a` | Pump 0 (Nano GPIO 2, M0) | ms FET-on time |
| `b` | Pump 1 (Nano GPIO 3, M1) | ms FET-on time |
| `c` | Pump 2 (Nano GPIO 4, M2) | ms FET-on time |
| `d` | Pump 3 (Nano GPIO 5, M3) | ms FET-on time |

The Nano runs the pumps **sequentially and blocking** ([`code/backend/code_arduino-nano/src/main.cpp:63-66`](../../code/backend/code_arduino-nano/src/main.cpp)) — the wall-clock cost of a `mix_*` is `a + b + c + d` ms plus ~550 ms of buzzer beeps.

The Flutter side computes the four values from a `Drink.pumpAmounts` list ([`code/frontend/lib/models/drink.dart`](../../code/frontend/lib/models/drink.dart)). The catalog values are calibration knobs — see [`../frontend/services.md`](../frontend/services.md) for the current numbers.

## End-to-end recipe trace (`mix_30_20_10_40`)

| Stage | Where | What |
|---|---|---|
| 1 | [`MockDrinkService._mapCocktailToDrink`](../../code/frontend/lib/services/drink_service.dart) | Cocktail id → `Drink` with `pumpAmounts = [30, 20, 10, 40]`. **Currently broken — see [known-issues.md](known-issues.md) F-1.** |
| 2 | [`BleMixerService.orderDrink`](../../code/frontend/lib/services/ble_mixer_service.dart) | Builds the literal `"mix_30_20_10_40"`, calls `_ble.send(...)`. |
| 3 | `BleService.send` → NUS RX | UTF-8 bytes `mix_30_20_10_40\n` arrive at the ESP. |
| 4 | ESP `loop()` | `msg.startsWith("mix_")` matches; calls `sendCMD(msg)` → `Serial1.println(msg)`. |
| 5 | Nano `loop()` | `espSerial.readStringUntil('\n')` returns the string; parser strips `mix_`, splits on `_` four times → `[30, 20, 10, 40]`. |
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

Crucial ordering: the Nano sends `mix_ok` (`main.cpp:69`) **before** it runs the buzzer (`main.cpp:72-78`). So the buzzer's 550 ms is *not* on the app's critical path — `BleMixerService.orderDrink` resolves and the UI reaches `drinkReady` while the buzzer is still beeping. The buzzer does, however, keep the Nano busy: it cannot accept a new `mix_*` for ~650 ms (100 ms pumping + 550 ms buzzer) after a command — see [`../arduino-nano/sequence-diagrams.md`](../arduino-nano/sequence-diagrams.md) §3.

The app's `waitForMessage('mix_ok')` defaults to a 60-second timeout — comfortable cushion against contention or button-press waits, but **does not** abort if the BLE link drops mid-flight (see [`../frontend/known-issues.md`](../frontend/known-issues.md) F-6).

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
