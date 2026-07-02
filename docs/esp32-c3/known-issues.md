# ESP32-C3 — Known issues

All line references are to [`code/backend/code_esp32-c3/src/main.cpp`](../../code/backend/code_esp32-c3/src/main.cpp).

These are real defects in the firmware as committed. The consolidated cross-codebase list lives in [`../cross-dependencies/known-issues.md`](../cross-dependencies/known-issues.md).

## Blockers — firmware cannot run end-to-end today

### 1. BLE stack is not implemented

| Symbol | Lines | State |
|---|---|---|
| `sendBLE(String cmd)` | 55–57 | empty body |
| `listenBLE()` | 61–63 | empty body, no `return` — undefined behaviour |

No `BLEDevice.h` / `BLEServer.h` / `BLE2902.h` includes are present and no library is declared in `platformio.ini`. Until a Nordic UART Service peripheral is set up, the `loop()` cannot receive `start` or `mix_*` and cannot notify the app. The reference skeleton to port in is in [`code/frontend/README.md`](../../code/frontend/README.md), lines 68–125.

### 6. `listenBLEBlocking(int)` is called but never defined — does not compile

`loop()` calls `listenBLEBlocking(30000)` at line 100 to wait for the per-round acknowledgement (`runde_ok` / `stop`), but there is no definition or declaration of `listenBLEBlocking` anywhere in the translation unit. **As committed, the firmware fails to build.** Either implement it (a blocking BLE read with a millisecond timeout, returning `""` on timeout) as part of the BLE port (§1), or the whole game loop is moot.

### 2. `listenBTNround(int i)` — multiple defects (lines 127–187)

The function is supposed to wait until **both** players have pressed a gesture button, then return `runde_<i>_<g1>_<g2>`. Today it returns immediately with empty gesture fields and reads the wrong pins for half the players.

| # | Defect |
|---|---|
| 2.1 | `b4 = digitalRead(B3); b5 = digitalRead(B3);` (twice, in the entry snapshot and inside the loop) — should read `B4` and `B5`. B4 and B5 are never actually sampled into the local snapshot. |
| 2.2 | `while(pl1 != "" && pl2 != "")` — inverted guard. Both strings start as `""`, so the loop body never executes. Should be `while(pl1 == "" \|\| pl2 == "")`. |
| 2.3 | `if(pl1 != "")` / `if(pl2 != "")` gate the *assignment* — also inverted. Once the outer loop is fixed, these need to be `==`. |
| 2.4 | B4 and B5 are read with raw `!digitalRead()` rather than `pressedStable()`, so they bypass the 10 ms debounce that B0–B3 use. |
| 2.5 | `lastB0..lastB5` are updated from the entry-time snapshot rather than the value freshly read inside the loop, so the rising-edge tracking is permanently stale. |

Result: even with the BLE layer in place, the game would either hang or report `runde_<i>__` per round.

## Hazards — won't crash but are footguns

### 3. Mix-relay error paths are swallowed

`listenCMD()` (lines 49–51) is now bounded by `Serial1.setTimeout(20000)` set in `setup()`, so a dead Nano no longer hangs the ESP forever — it returns an empty string after 20 s (chosen shorter than the app's 30 s / 60 s BLE waits so the app can react first). **But** the `mix_*` branch (lines 110–116) only relays on an exact `"mix_ok"`:

- A `mix_err` NAK from the Nano (now emitted on malformed input — see [`../arduino-nano/known-issues.md`](../arduino-nano/known-issues.md)) is read and then dropped; the app never learns the mix failed and falls back to its own BLE timeout.
- A `listenCMD` timeout is likewise silently ignored.

Relay the failure to the app (e.g. `sendBLE("mix_err")`) so the frontend can react immediately instead of waiting out a timeout.

### 4. Dead `btnTest()` (lines 195–276)

Never referenced from `setup()` or `loop()`. The body contains a verbatim duplicate of the first half and updates only `lastB0..lastB3` at the end (`lastB4`–`lastB9` left untouched). Remove or wire into a real diagnostic command before relying on it.

### 5. B6–B9 never sampled by the game logic

`setup()` configures them as `INPUT_PULLUP`, but `listenBTNround()` only ever looks at B0–B5. If those buttons are intended for future "manual pump" controls (the comment at `code/backend/code_arduino-nano/src/main.cpp:87` says `// TODO: add logic for manual pumping`), they are reserved but inert.

### 7. `Serial1.begin` called twice in `setup()`

Lines 79 and 82 both call `Serial1.begin(9600, SERIAL_8N1, RXD1, TXD1)`, with the `Serial1.setTimeout(20000)` sandwiched between them. The second `begin` is redundant. Harmless, but confusing — drop one.

## Action checklist before declaring "feature complete"

- [ ] Port the NUS skeleton from `frontend/README.md` into `main.cpp`; add the BLE Arduino libs as dependencies (§1).
- [ ] Implement `listenBLEBlocking(timeoutMs)` (or remove the call) so the firmware compiles (§6).
- [ ] Rewrite `listenBTNround()` per defects 2.1–2.5; ideally with one debounce path (`pressedStable`) for all six buttons.
- [ ] Relay `mix_err` / relay-timeout back to the app instead of dropping them (§3).
- [ ] Decide on B6–B9: implement manual pumping or delete the unused pull-ups from `setup()`.
- [ ] Delete `btnTest()` or fold it into a proper `#ifdef DEBUG` block; drop the duplicate `Serial1.begin`.
