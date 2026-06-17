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

### 2. `listenBTNround(int i)` — multiple defects (lines 114–174)

The function is supposed to wait until **both** players have pressed a gesture button, then return `runde_<i>_<g1>_<g2>`. Today it returns immediately with empty gesture fields and reads the wrong pins for half the players.

| # | Lines | Defect |
|---|---|---|
| 2.1 | 120–121, 134–135 | `b4 = digitalRead(B3); b5 = digitalRead(B3);` — should be `digitalRead(B4)` and `digitalRead(B5)`. B4 and B5 are never actually sampled into the local snapshot. |
| 2.2 | 129 | `while(pl1 != "" && pl2 != "")` — inverted guard. Both strings start as `""`, so the loop body never executes. Should be `while(pl1 == "" \|\| pl2 == "")`. |
| 2.3 | 137, 151 | `if(pl1 != "")` and `if(pl2 != "")` gate the *assignment* — also inverted. Once the outer loop is fixed, these need to be `==`. |
| 2.4 | 156, 160 | B4 and B5 are read with raw `!digitalRead()` rather than `pressedStable()`, so they bypass the 10 ms debounce that B0–B3 use. |
| 2.5 | 166–171 | `lastB0..lastB5` are updated from the entry-time snapshot (`b0..b5` captured at lines 116–121) rather than the value freshly read inside the loop, so the rising-edge tracking is permanently stale. |

Result: even with the BLE layer in place, the game would either hang or report `runde_<i>__` per round.

## Hazards — won't crash but are footguns

### 3. `listenCMD()` blocks forever (lines 49–51)

`Serial1.readStringUntil('\n')` has no timeout. If the Nano dies or never answers `mix_ok`, the ESP loop hangs. A `Serial1.setTimeout(...)` followed by a length check would make this recoverable.

### 4. Dead `btnTest()` (lines 182–263)

Never referenced from `setup()` or `loop()`. The body contains a verbatim duplicate of the first half (lines 191–216 and 219–250 are the same checks) and updates only `lastB0..lastB3` at the end (`lastB4`–`lastB9` left untouched). Remove or wire into a real diagnostic command before relying on it.

### 5. B6–B9 never sampled by the game logic

`setup()` configures them as `INPUT_PULLUP`, but `listenBTNround()` only ever looks at B0–B5. If those buttons are intended for future "manual pump" controls (the comment at `code/backend/code_arduino-nano/src/main.cpp:83` says `// TODO: add logic for manual pumping`), they are reserved but inert.

## Action checklist before declaring "feature complete"

- [ ] Port the NUS skeleton from `frontend/README.md` into `main.cpp`; add the BLE Arduino libs as dependencies.
- [ ] Rewrite `listenBTNround()` per defects 2.1–2.5; ideally with one debounce path (`pressedStable`) for all six buttons.
- [ ] Add a timeout to `listenCMD()` and surface mix-relay failures back to the app (e.g. a `mix_err` notify).
- [ ] Decide on B6–B9: implement manual pumping or delete the unused pull-ups from `setup()`.
- [ ] Delete `btnTest()` or fold it into a proper `#ifdef DEBUG` block.
