# Arduino Nano — Known issues

All line references are to [`code/backend/code_arduino-nano/src/main.cpp`](../../code/backend/code_arduino-nano/src/main.cpp). The consolidated cross-codebase list lives in [`../cross-dependencies/known-issues.md`](../cross-dependencies/known-issues.md).

## Hazards — won't currently misbehave but will bite later

### 1. `#define B0 8` collides with `SoftwareSerial` RX

```cpp
SoftwareSerial espSerial(8, 9); // line 6, RX=8 TX=9
#define B0 8                    // line 13
```

`B0` is declared but never read or written in `main.cpp`, so the collision is dormant. If a future change calls `pinMode(B0, INPUT)` or `digitalRead(B0)`, it will interfere with the UART receive path. Either delete the `#define` or pick a free pin.

### 2. `Adafruit_VL53L0X` library declared but unused

`platformio.ini` pulls `adafruit/Adafruit_VL53L0X@^1.2.5`, but `main.cpp` has no `#include <Adafruit_VL53L0X.h>` and no sensor object (only `#include <Wire.h>`, itself unused). The VL53L0X on the schematic (`schaltplan/sketch_bom.html`) is wired to the ESP32-C3, not the Nano. The dependency adds build time and flash overhead for nothing — drop it from `lib_deps`.

### 3. Manual-pump feature is a TODO

```cpp
// TODO: add logic for manual pumping
```

At [`main.cpp:87`](../../code/backend/code_arduino-nano/src/main.cpp). No code path exists to drive the pumps without an upstream `mix_*` command. The ESP32 has unused buttons `B6`–`B9` (`code_esp32-c3/src/main.cpp:8-12`) that may be intended for this, but neither side implements it.

### 5. Pumps run blocking, in sequence

`pump()` uses `delay()` (line 22). The total time the loop is unavailable equals `Σ durations`. While the pumps run the Nano cannot read from `espSerial`, so any second `mix_*` queued by the ESP would be dropped if it overflowed the SoftwareSerial RX buffer. In practice the ESP waits for `mix_ok` before sending another order (and drains stale RX bytes before each mix), so this is currently moot — but it constrains any future "abort mix" command, which would need a non-blocking driver (e.g. `millis()`-based scheduling or a timer ISR).

## Resolved

### 4. No NAK on malformed `mix_*` — **RESOLVED**

Previously the Nano printed `"Invalid message format"` only on USB and stayed silent on `espSerial`, so a malformed frame would hang the ESP's `listenCMD()`. The parser (lines 51–66) now emits `espSerial.println("mix_err")` before returning (line 57), so the upstream side gets an explicit NAK. Note the ESP does not yet *relay* that NAK to the app — see [`../esp32-c3/known-issues.md` §3](../esp32-c3/known-issues.md).

## Action checklist before declaring "feature complete"

- [ ] Remove `#define B0 8` or relocate it to a free pin and document its purpose.
- [ ] Drop `adafruit/Adafruit_VL53L0X` from `lib_deps` (and the unused `#include <Wire.h>`).
- [ ] Implement manual-pump handling for whichever buttons the ESP forwards — and add the matching ESP-side `sendCMD` calls.
- [ ] If concurrent commands become a requirement, replace `delay()` in `pump()` with a non-blocking scheduler.
