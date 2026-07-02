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

### App → ESP (received via `listenBLE()` / `listenBLEBlocking()` — currently stubbed/undefined)

| Message | When | ESP's expected reaction |
|---|---|---|
| `start` | App kicks off a new game. | Reply `start_ok`, then enter the round-collection loop. |
| `runde_ok` | App acknowledged a round result and wants the next round. | Increment the round counter and collect the next round. |
| `stop` | App has ended the series (2-win majority or 3 rounds reached). | Leave the round loop and return to idle. |
| `mix_a_b_c_d` | App orders a drink with per-pump durations `a..d`. | Drain stale UART bytes, forward verbatim to Nano via `sendCMD`, await the Nano's `mix_ok`, then notify the app with `mix_ok`. |

`stop` is new relative to the earlier fixed-3-round protocol: the app, not the firmware, decides when the best-of-three series is over, and signals it explicitly. The round-wait also breaks out on an empty read (timeout/disconnect) so the firmware does not hang.

### ESP → App (sent via `sendBLE()` — currently a stub)

| Message | Format | Meaning |
|---|---|---|
| `start_ok` | literal | Game accepted. |
| `runde_<i>_<g1>_<g2>` | `i` ∈ `{0,1,2}`, `g1`/`g2` ∈ `{0=rock, 1=paper, 2=scissors}` | One round's result. Constructed in `listenBTNround()` (lines 127–187). |
| `mix_ok` | literal | Mix relay succeeded; relayed from the Nano. |

> The firmware does **not** currently relay a `mix_err` or a relay-timeout to the app — see [known-issues.md §3](known-issues.md). The reference NUS implementation that has to be ported into this firmware lives in [`code/frontend/README.md`](../../code/frontend/README.md) lines 68–125 (Arduino `BLEDevice`/`BLEServer`/`BLE2902` skeleton).

## B — UART to the Nano (`Serial1`, 9600 8N1)

| Direction | Message | Source / sink in code |
|---|---|---|
| ESP → Nano | `mix_a_b_c_d` (forwarded verbatim from BLE) | `sendCMD(msg)` at `main.cpp:112`, body lines 41–45 |
| Nano → ESP | `mix_ok` | `listenCMD()` (20 s timeout) at `main.cpp:113`, body lines 49–51 |
| Nano → ESP | `mix_err` | Emitted by the Nano on malformed input; read by `listenCMD()` but **not** relayed to the app today ([known-issues.md §3](known-issues.md)). |

Both directions terminate with `\n`. `listenCMD` honours the 20 s timeout set by `Serial1.setTimeout(20000)` in `setup()`. The ESP does **not** parse `mix_a_b_c_d` itself — it is opaque pass-through to the Nano.

`btnTest()` (dead code, lines 195–276) contains additional debug strings (`"Beep"`, `"No Beep!"`, `"Button0On"`, `"Button0Off"`) that would be sent over `Serial1` if the function were ever called. The Nano does not handle them.

## Encoding cheat-sheet

| Domain | Value | Encoding |
|---|---|---|
| Round index | first / second / third | `0` / `1` / `2` |
| Gesture | Rock | `0` |
| Gesture | Paper | `1` |
| Gesture | Scissors | `2` |
| Mix amount | per pump, milliseconds of pump-on time | unsigned integer literal |

## What still has to land before BLE works

See [known-issues.md](known-issues.md). The pin map, UART relay, and round-message format are all wired; the BLE stack (§1), the undefined `listenBLEBlocking` (§6), and the `listenBTNround()` bugs (§2) stand between this firmware and an end-to-end game.
