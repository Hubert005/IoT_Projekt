# Arduino Nano — Runtime

All references are to [`code/backend/code_arduino-nano/src/main.cpp`](../../code/backend/code_arduino-nano/src/main.cpp).

## Build configuration

From [`platformio.ini`](../../code/backend/code_arduino-nano/platformio.ini):

| Key | Value |
|---|---|
| `platform` | `atmelavr` |
| `board` | `nanoatmega328` |
| `framework` | `arduino` |
| `monitor_speed` | `115200` |
| `build_flags` | `-D ARDUINO_USB_MODE=1`, `-D ARDUINO_USB_CDC_ON_BOOT=1` |
| `lib_deps` | `adafruit/Adafruit_VL53L0X@^1.2.5` — **declared but never `#include`d**; see [known-issues.md](known-issues.md). |

## Pin map

| Symbol | GPIO | Mode | Role |
|---|---|---|---|
| `M0` | 2  | `OUTPUT` | Pump 0 gate (N-channel FET) |
| `M1` | 3  | `OUTPUT` | Pump 1 gate |
| `M2` | 4  | `OUTPUT` | Pump 2 gate |
| `M3` | 5  | `OUTPUT` | Pump 3 gate |
| `BUZZER` | 10 | `OUTPUT` | Piezo buzzer (mix-done pattern) |
| `B0` | 8 | — *(declared, never set)* | **Collides with `SoftwareSerial` RX on pin 8** — see [known-issues.md](known-issues.md). |
| `espSerial` RX | 8 | `SoftwareSerial` | UART from ESP32-C3 |
| `espSerial` TX | 9 | `SoftwareSerial` | UART to ESP32-C3 |

Two serial channels run at different baud rates: hardware `Serial` (USB CDC) is 115200 for dev-host monitoring, `espSerial` is 9600 — slower but more reliable under SoftwareSerial's bit-banged timing.

## Functions

### `pump(int Motor, int duration)` — lines 20–24

```cpp
void pump(int Motor, int duration){
  digitalWrite(Motor, HIGH);
  delay (duration);
  digitalWrite(Motor, LOW);
}
```

Drives one FET high for `duration` ms. Blocking. No PWM, no current monitoring, no upper-bound check.

### `setup()` — lines 26–36

1. `pinMode` each of `BUZZER`, `M0`–`M3` as `OUTPUT`.
2. Open USB `Serial` at 115200.
3. Open `espSerial` at 9600.
4. Print `"Serial Started"` on USB.

### `loop()` — lines 38–84

For the visual flow see [sequence-diagrams.md](sequence-diagrams.md) §2 (idle poll) and §3 (mix happy path). Step-by-step (lines 40–79):

1. **Receive** (40–47): poll `espSerial.available()`; on a frame, `readStringUntil('\n')`, `trim()`, and echo to USB (`Serial.println("Nano got: " + msg)`).
2. **Filter** (50): only act when `msg.startsWith("mix_")`.
3. **Parse** (51–62): strip the four-character `"mix_"` prefix, then loop four times, locating the next `_`, slicing the substring, and converting with `String::toInt()`. If any underscore is missing the function `return`s after `Serial.println("Invalid message format")`.
4. **Drive pumps** (63–66): `pump(M0 + i, durations[i])` for `i ∈ {0,1,2,3}`. The arithmetic relies on `M0..M3` being consecutive pins 2..5 — change one and the loop breaks.
5. **Acknowledge** (69): `espSerial.println("mix_ok")`.
6. **Buzz** (72–78): two 250 ms tones with 50 ms silence between them.
7. **Reset** (81): `msg = ""` so the next iteration starts clean.

## Wiring summary

From [`schaltplan/sketch_bom.html`](../../schaltplan/sketch_bom.html) the dispensing side carries:

- 4 DC pump motors (M0–M3), each gated by an N-channel MOSFET, with a Schottky fly-back diode across the motor coil.
- 1 piezo buzzer on GPIO 10.
- Two signal-conditioning resistors (R1 ≈ 1 kΩ, R2 ≈ 1.5 kΩ).
- 8 pushbuttons (S1–S8) and the VL53L0X distance sensor are also on the schematic but are **wired to the ESP32-C3**, not the Nano.

## Hardware-debug fast path

Every UART message from the ESP is echoed to USB `Serial` (line 44–45). With `pio device monitor` you can confirm the Nano received a well-formed `mix_*` order without instrumenting the ESP. Malformed orders also surface as `"Invalid message format"` on USB.
