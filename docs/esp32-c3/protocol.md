# ESP32-C3 — Protocol surface

This page describes the wire interfaces of the ESP32 firmware **as the ESP sees them**. The cross-codebase canonical version is [`../cross-dependencies/protocol.md`](../cross-dependencies/protocol.md); if the two ever disagree, the cross-dependencies file is authoritative.

## Two interfaces

```
 ┌──────────────┐    BLE NUS    ┌────────────┐   Serial1 9600 8N1   ┌─────────────┐
 │  Flutter App │ <───────────> │  ESP32-C3  │ <──────────────────> │ Arduino Nano│
 └──────────────┘               └────────────┘                       └─────────────┘
```

## A — BLE (Nordic UART Service)

UUIDs the ESP firmware must expose:

| Role | UUID | Property |
|---|---|---|
| Service | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | — |
| RX char (app → ESP) | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | WRITE / WRITE_NR |
| TX char (ESP → app) | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | NOTIFY (with CCCD) |

Messages are ASCII strings terminated by `\n`.

### App → ESP (received via `listenBLE()` — currently a stub)

| Message | When | ESP's expected reaction |
|---|---|---|
| `start` | App kicks off a new game. | Reply `start_ok`, then run 3 rounds. |
| `runde_ok` | App acknowledged a round result. | Proceed to the next round (inner `while` at `main.cpp:93`). |
| `mix_a_b_c_d` | App orders a drink with per-pump durations `a..d` in ms. | Forward verbatim to Nano via `sendCMD`, await Nano's `mix_ok`, then notify the app with `mix_ok`. |

### ESP → App (sent via `sendBLE()` — currently a stub)

| Message | Format | Meaning |
|---|---|---|
| `start_ok` | literal | Game accepted. |
| `runde_<i>_<g1>_<g2>` | `i` ∈ `{0,1,2}`, `g1`/`g2` ∈ `{0=rock, 1=paper, 2=scissors}` | One round's result. Constructed in `listenBTNround()` (lines 114–174). |
| `mix_ok` | literal | Mix relay succeeded; relayed from the Nano. |

The reference implementation that has to be ported into this firmware lives in [`code/frontend/README.md`](../../code/frontend/README.md) lines 68–125 (Arduino `BLEDevice`/`BLEServer`/`BLE2902` skeleton).

## B — UART to the Nano (`Serial1`, 9600 8N1)

| Direction | Message | Source / sink in code |
|---|---|---|
| ESP → Nano | `mix_a_b_c_d` (forwarded verbatim from BLE) | `sendCMD(msg)` at `main.cpp:99`, body lines 41–45 |
| Nano → ESP | `mix_ok` | `listenCMD()` (blocking) at `main.cpp:100`, body lines 49–51 |

Both directions terminate with `\n`. The ESP does **not** parse `mix_a_b_c_d` itself — it is opaque pass-through to the Nano.

`btnTest()` (dead code, lines 182–263) contains additional debug strings (`"Beep"`, `"No Beep!"`, `"Button0On"`, `"Button0Off"`) that would be sent over `Serial1` if the function were ever called. The Nano does not handle them.

## Encoding cheat-sheet

| Domain | Value | Encoding |
|---|---|---|
| Round index | first / second / third | `0` / `1` / `2` |
| Gesture | Rock | `0` |
| Gesture | Paper | `1` |
| Gesture | Scissors | `2` |
| Mix amount | per pump, milliseconds of pump-on time | unsigned integer literal |

## What still has to land before BLE works

See [known-issues.md](known-issues.md). The pin map, UART relay, and round-message format are all wired; only the BLE stack and the `listenBTNround()` bugs stand between this firmware and an end-to-end game.
