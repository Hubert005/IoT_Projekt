# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Three independent codebases that talk to each other over BLE + UART:

- `code/backend/code_esp32-c3/` — ESP32-C3 firmware (PlatformIO/Arduino). BLE peripheral that the Flutter app talks to, plus button matrix and `Serial1` link to the Nano.
- `code/backend/code_arduino-nano/` — Arduino Nano firmware (PlatformIO/Arduino). Drives the 4 pump motors and buzzer over `SoftwareSerial`.
- `code/frontend/` — Flutter app `iot_drink_mixer` ("Braincell Massacre" / Gehirnzellen Massaker). The phone is the BLE central.

**Documentation lives under [`docs/`](docs/README.md)** — start there before reading source for orientation. The canonical wire-format spec is [`docs/cross-dependencies/protocol.md`](docs/cross-dependencies/protocol.md); it supersedes the partial protocol notes in `kommunikationsablauf.md` and `code/frontend/README.md` (both still useful as quick references). The consolidated bug log is [`docs/cross-dependencies/known-issues.md`](docs/cross-dependencies/known-issues.md) — check it before claiming a feature works.

Note: there are stub `code/code_arduino-nano/` and `code/code_esp32-c3/` directories with only `.pio`/`.vscode` artifacts. The real firmware lives under `code/backend/`.

## Build & run

### Flutter app (`code/frontend/`)
```bash
flutter pub get
flutter run
flutter analyze       # lint
flutter test          # all tests
flutter test test/path/to/file_test.dart   # single test file
dart format .
```
Hardware-free development: from the home page tap **"Test Modus (ohne ESP32)"**. `BleService.enableTestMode()` makes `send()` push to `sentMessages` instead of writing to BLE, and `inject(...)` simulates incoming messages. Any new feature must continue to work in test mode.

### Firmware (`code/backend/code_esp32-c3/` and `code/backend/code_arduino-nano/`)
PlatformIO from each directory:
```bash
pio run                # build
pio run -t upload      # flash
pio device monitor     # serial monitor (115200 baud)
```
Boards: `esp32-c3-devkitm-1` and `nanoatmega328`. ESP32 talks to the Nano on `Serial1` (RX=21, TX=20) at 9600 baud; the Nano side uses `SoftwareSerial(8, 9)` at 9600.

## BLE/UART protocol (do not break silently)

Nordic UART Service. UUIDs in `lib/services/ble_service.dart:15-17` and the README must match the ESP firmware.

```
App ──"start"──▶ ESP             ESP ──"start_ok"──▶ App
ESP ──"runde_<i>_<g1>_<g2>"──▶ App   App ──"runde_ok"──▶ ESP   (×3 rounds)
App ──"mix_<a>_<b>_<c>_<d>"──▶ ESP   ESP relays over UART to Nano,
                                     Nano ──"mix_ok"──▶ ESP ──"mix_ok"──▶ App
```
- Gestures: `0`=Stein, `1`=Papier, `2`=Schere.
- `mix_a_b_c_d`: per-pump duration/quantity in the order pump0..pump3. The frontend stores per-drink amounts in `lib/services/drink_service.dart` (`pumpAmounts`); these are calibration values, edit them there.
- The ESP just forwards `mix_*` to the Nano verbatim and waits for `mix_ok` before relaying it to the app. Keep that round-trip intact when modifying either side.

## Frontend architecture

Feature-first layout under `lib/`:
- `features/{home,game,recipes}/` — UI per feature.
- `services/` — singletons (`BleService`, `BleBackendService`, `BleMixerService`) plus mock/interface variants (`backend_service.dart`, `drink_service.dart`, `mixer_service.dart`, `mock_cocktail_service.dart`) so screens can be wired against either real BLE or a mock for test mode.
- `models/` — `Gesture` (with `versus()` win logic), `RoundResult`, `Drink`, `Cocktail`.
- `core/theme/` — `AppTheme`, `AppColors`, `AppRadius`, `AppTextStyles`. Use these instead of hard-coded colors/sizes.
- ML Kit integration (`google_mlkit_face_detection`, `google_mlkit_image_labeling`) is used by `image_analyzer_service.dart` and `google_ml_kit_cocktail_service.dart` for image-based features; `camera`/`image_picker` feed it.

`BleService` is a singleton accessed via `BleService.instance`. It exposes `messageStream`, `connectionStream`, `sentMessages` (test-mode echo), and `waitForMessage(prefix, timeout:)` for request/response style flows. Always `dispose` subscriptions/controllers in widgets that subscribe.

## Documentation index (read these before re-deriving from source)

| Folder | Use when |
|---|---|
| [`docs/README.md`](docs/README.md) | Top-level orientation and folder map. |
| [`docs/cross-dependencies/`](docs/cross-dependencies/README.md) | Authoritative wire-format spec, sequence diagrams, consolidated known-issues table. |
| [`docs/esp32-c3/`](docs/esp32-c3/README.md) | ESP32-C3 firmware: pin map, runtime, BLE/UART protocol surface, known bugs (BLE is currently stubbed). |
| [`docs/arduino-nano/`](docs/arduino-nano/README.md) | Arduino Nano firmware: pin map, `mix_*` parser walkthrough, pin-collision footgun. |
| [`docs/frontend/`](docs/frontend/README.md) | Flutter app: services / features / ML pipeline / known issues. |

Future sessions should explore via these docs first; only fall back to reading source when a doc doesn't cover the question.

## Project conventions (from existing AI guidance)

The frontend has its own Copilot rules in `code/frontend/copilot-instructions.md`, `.agents.md`, `.instructions.md`, and `.skills.md`. The load-bearing points:
- Keep changes small and targeted; don't restructure existing architecture without a reason.
- Don't change BLE message formats without updating both the ESP32 firmware and the frontend README.
- New logic must work in test mode (no hardware).
- Maintain UI/service/BLE separation — UI screens consume services, services own the BLE handle.
- Reuse `core/theme/` rather than inlining colors or radii.
