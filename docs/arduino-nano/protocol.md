# Arduino Nano — Protocol surface

This page describes the wire interface of the Nano firmware **as the Nano sees it**. The cross-codebase canonical version is [`../cross-dependencies/protocol.md`](../cross-dependencies/protocol.md); if the two ever disagree, the cross-dependencies file is authoritative.

The Nano has exactly one wire interface to another microcontroller: `SoftwareSerial` on pins 8/9 at 9600 baud, 8N1, talking to the ESP32-C3. USB `Serial` (115200 baud) is dev-host only and carries no protocol — purely human-readable echoes.

## ESP32-C3 → Nano (`espSerial` RX, pin 8)

| Message | Format | Action |
|---|---|---|
| `mix_<a>_<b>_<c>_<d>` | four unsigned integer literals separated by `_`, terminated by `\n` | Run pumps M0, M1, M2, M3 sequentially for `a`, `b`, `c`, `d` milliseconds respectively, then ack (`mix_ok`) and buzz. See [runtime.md](runtime.md) for the parser walk-through. |

Field semantics:

| Field | Maps to | Unit |
|---|---|---|
| `a` | Pump 0 (M0, GPIO 2) | ms of FET-on time |
| `b` | Pump 1 (M1, GPIO 3) | ms of FET-on time |
| `c` | Pump 2 (M2, GPIO 4) | ms of FET-on time |
| `d` | Pump 3 (M3, GPIO 5) | ms of FET-on time |

Behavioural notes:

- Any message that does **not** start with `mix_` is silently dropped (it is still echoed to USB `Serial` as `"Nano got: …"`).
- A `mix_*` message that is missing a `_` separator before the fourth field sends `mix_err` back on `espSerial`, prints `"Invalid message format"` on USB, and returns without pumping or acking. The fourth field itself needs no trailing `_` — the parser takes the remainder of the string.
- Durations are not bounded. A pathologically large `a` will block the loop for that many ms.

## Nano → ESP32-C3 (`espSerial` TX, pin 9)

| Message | When |
|---|---|
| `mix_ok\n` | Emitted at `main.cpp:73`, immediately after all four pumps complete, **before** the buzzer pattern. |
| `mix_err\n` | Emitted at `main.cpp:57` when the `mix_*` payload is malformed (a NAK, so the ESP need not wait out a timeout). |

These are the only two messages the Nano ever sends on `espSerial`. No status pings.

## Other (USB `Serial`, 115200 baud — dev only)

| Direction | Message | Purpose |
|---|---|---|
| Nano → host | `Serial Started` | One-shot at boot (`main.cpp:35`). |
| Nano → host | `Nano got: <msg>` | Every non-empty line received on `espSerial` (lines 44–45). |
| Nano → host | `Invalid message format` | Malformed `mix_*` (line 58). |

These are debugging aids, not contracts. Nothing parses them programmatically.

## Encoding cheat-sheet

| Symbol on the wire | Type | Range used in practice |
|---|---|---|
| `_` | field separator | literal |
| `\n` | frame terminator | literal |
| integer literal | decimal ASCII, no sign, no padding | 0…~80 ms per pump in current recipes (generated pool caps a pump at 80 and a drink's total at 250) |

If a recipe needs more than four pumps or different units, this protocol must change — and so must the ESP relay (`main.cpp:112` in the ESP32 firmware, which forwards verbatim) and the Flutter `BleMixerService`. See [`../cross-dependencies/protocol.md`](../cross-dependencies/protocol.md) for the joint change checklist.
