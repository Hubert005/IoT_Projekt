# Copilot Instructions – IoT Drink Mixer

## Project Overview

**Rock-Paper-Scissors drinking game** with BLE communication to an ESP32-powered drink mixer.

**Stack**: Flutter (Dart 3.7+) | BLE (Nordic UART NUS) | ESP32 Backend | Multi-platform (iOS, Android, Web, Linux, macOS, Windows)

For detailed architecture and protocol specs, see [README.md](README.md).

## Essential Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on device
dart format .              # Format code
flutter analyze            # Lint check
flutter test               # Run tests
```

## Architecture at a Glance

**Feature-based structure** with singleton services:

```
lib/
├── features/{home, game, recipes}/    # Self-contained feature modules
├── services/ble_*.dart                # BLE/mixer/drink singleton services
├── models/                            # Gesture, RoundResult, Drink
└── core/theme/                        # App styling
```

**Key Pattern**: BLE via `StreamController`, services injected for testability.

## BLE Protocol Rules

- Nordic UART Service with specific message formats:
  - `start` ↔ `start_ok`
  - `runde_1_0_2` ↔ `runde_ok` (round, gesture1, gesture2)
  - `mix_30_20_10_40` ↔ `mix_ok` (ml per pump)
- **Do not** change message formats silently — update ESP32 firmware and README
- Test mode (`BleService.enableTestMode()`) must remain functional

## Development Guardrails

1. **Respect existing architecture** – avoid unnecessary restructuring
2. **Test mode first** – new logic must work without hardware
3. **Service boundaries** – keep UI/logic/BLE separated
4. **Lifecycle cleanup** – dispose controllers and listeners properly
5. **Small, targeted changes** – touch only affected files
6. **Backward compatibility** – especially for BLE, recipes, and mixing logic

## Core Files

| File | Purpose |
|------|---------|
| [lib/services/ble_service.dart](lib/services/ble_service.dart) | Singleton BLE connection & NUS protocol |
| [lib/services/ble_backend_service.dart](lib/services/ble_backend_service.dart) | Receives and parses game commands |
| [lib/services/ble_mixer_service.dart](lib/services/ble_mixer_service.dart) | Sends mix orders to ESP32 |
| [lib/models/gesture.dart](lib/models/gesture.dart) | Gesture enum with `versus()` logic |
| [lib/features/game/game_screen.dart](lib/features/game/game_screen.dart) | Game flow orchestration |
| [lib/services/drink_service.dart](lib/services/drink_service.dart) | Pump mappings and drink recipes |

## When in Doubt

- Review existing code and README first
- Prefer conservative changes over breaking the protocol
- Reuse theme, services, and existing patterns
- Cover error cases and empty states
- Keep UI text clear and consistent
