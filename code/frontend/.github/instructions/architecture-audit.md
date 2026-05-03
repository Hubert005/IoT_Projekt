# Architecture Audit Instruction

Use this checklist to validate that new code adheres to the app's architectural patterns and conventions.

## Lifecycle Management

**Before Approval**: Every StatefulWidget must clean up properly.

### Checklist

- [ ] All `StreamSubscription` objects stored and disposed
- [ ] All `TextEditingController` disposed in `dispose()`
- [ ] All listeners (e.g., `BleService.connectionState.listen()`) canceled
- [ ] `super.dispose()` called last
- [ ] No memory leaks from lingering listeners

### Example

```dart
class MyScreenState extends State<MyScreen> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = BleService.instance.connectionState.listen((_) {
      setState(() { /* update */ });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();  // ✅ Clean up
    super.dispose();
  }
}
```

## Service Singleton Pattern

**Enforce**: Services are accessed via `.instance`, never instantiated locally.

### Checklist

- [ ] `BleService.instance` used (not `BleService()`)
- [ ] `DrinkService.instance` used consistently
- [ ] `MixerService.instance` used consistently
- [ ] No new service instances created in widgets
- [ ] DI pattern used for testing (optional: `service ?? ServiceType.instance`)

### Valid Patterns

```dart
// ✅ Singleton access
final bleService = BleService.instance;

// ✅ Dependency injection for tests
MyClass({BleService? ble}) : bleService = ble ?? BleService.instance;

// ❌ Avoid direct instantiation
// final bleService = BleService();
```

## Test Mode Compatibility

**Verify**: New features work without real ESP32.

### Checklist

- [ ] Code handles `BleService.isTestMode == true`
- [ ] Mock data rendered correctly in test mode
- [ ] No crashes when BLE connection absent
- [ ] Tested manually: `BleService.enableTestMode()`
- [ ] Empty state UI defined

### Example

```dart
StreamBuilder(
  stream: BleService.instance.connectionState,
  builder: (context, snapshot) {
    if (BleService.instance.isTestMode) {
      return const Text('(Test Mode)');  // Show indicator
    }
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }
    // Normal UI
  },
)
```

## BLE Protocol Compliance

**For BLE-related changes**: Verify protocol integrity.

### Checklist

- [ ] Message strings trimmed before parsing
- [ ] No silent protocol changes (update README if changed)
- [ ] Command format matches ESP32 firmware
- [ ] Error handling for malformed messages
- [ ] Test mode inject works without hardware

### Valid Message Formats

```dart
// Game protocol
"runde_1_0_2"    // round #, gesture1, gesture2

// Mix protocol
"mix_30_20_10_40"  // ml per pump (4 pumps)

// Always trim before parsing
final parts = message.trim().split('_');
```

## Widget & UI Structure

**Enforce**: Features use consistent structure.

### Checklist

- [ ] Main screen in `screens/{feature}_screen.dart`
- [ ] Reusable widgets in `widgets/` folder
- [ ] No UI code in services
- [ ] No service calls in widget `build()` method
- [ ] Local state managed in StatefulWidget or provider

### Valid Structure

```
lib/features/my_feature/
├── screens/
│   └── my_feature_screen.dart
├── widgets/
│   ├── my_card.dart
│   └── my_header.dart
├── models/
│   └── my_state.dart
└── my_feature_provider.dart (optional)
```

## State Management Rules

**Enforce**: Predictable state flow.

### Checklist

- [ ] UI state managed in StatefulWidget (simple) or provider (complex)
- [ ] BLE state accessed via `StreamBuilder`
- [ ] No service state mutations in UI code
- [ ] Navigation doesn't lose state unexpectedly
- [ ] Error states handled explicitly

### Pattern

```dart
StreamBuilder<BleConnectionState>(
  stream: BleService.instance.connectionState,
  builder: (context, snapshot) {
    // Handle states: AsyncSnapshot.none, waiting, withData, withError
    if (snapshot.hasError) {
      return ErrorWidget(error: snapshot.error);
    }
    // ... render normal UI
  },
)
```

## Common Architecture Violations

### ❌ Violation 1: Direct Service Instantiation
```dart
final service = DrinkService();  // WRONG
```
✅ **Fix**: Use singleton instance
```dart
final service = DrinkService.instance;
```

### ❌ Violation 2: BLE State Not Disposed
```dart
@override
void initState() {
  BleService.instance.connectionState.listen((_) { /* */ });
  // Missing disposal
}
```
✅ **Fix**: Store subscription and dispose
```dart
late StreamSubscription _sub;

@override
void initState() {
  _sub = BleService.instance.connectionState.listen((_) { /* */ });
}

@override
void dispose() {
  _sub.cancel();
  super.dispose();
}
```

### ❌ Violation 3: Silent Protocol Changes
```dart
// Changes BLE message format without updating firmware or docs
```
✅ **Fix**: Coordinate with README and ESP32 firmware
```dart
// In messages.dart: Document any protocol changes
// Updated: Mix format now supports 5 pumps: "mix_a_b_c_d_e"
```

### ❌ Violation 4: Not Testing Without Hardware
Feature looks good with real ESP32, but crashes in test mode.

✅ **Fix**: Always test both
```bash
# Manual test
BleService.enableTestMode();
flutter run
```

## Audit Checklist Summary

Before merging any feature or service changes, verify:

- [ ] **Lifecycle**: All subscriptions/listeners disposed
- [ ] **Services**: Using `.instance`, not instantiating
- [ ] **Test Mode**: Feature works without ESP32
- [ ] **BLE Protocol**: No silent changes, README updated if needed
- [ ] **Structure**: Feature follows scaffold template
- [ ] **State**: Explicit state management, no mutations in UI
- [ ] **UI**: Consistent theme colors/spacing (see UI Consistency Skill)

## Project Context

- [lib/services/ble_service.dart](../../../lib/services/ble_service.dart) – singleton pattern reference
- [lib/features/game/game_screen.dart](../../../lib/features/game/game_screen.dart) – complex lifecycle example
- [lib/models/](../../../lib/models/) – domain model patterns
- [README.md](../../../README.md) – protocol specification
