# Feature Scaffold Instruction

Follow this guide to quickly scaffold new features while maintaining architecture consistency.

## Feature Structure

Every new feature lives in `lib/features/{feature_name}/` with this structure:

```
lib/features/{feature_name}/
├── screens/
│   └── {feature_name}_screen.dart           # Main screen (if applicable)
├── widgets/
│   ├── {feature_name}_card.dart             # Reusable components
│   └── {feature_name}_header.dart
├── models/
│   └── {feature_name}_state.dart            # Local state models (if complex)
└── {feature_name}_provider.dart             # Optional: if using state provider
```

### Quick Checklist

- [ ] Feature folder created in `lib/features/{name}/`
- [ ] Main screen in `screens/{name}_screen.dart`
- [ ] Reusable widgets in `widgets/` folder
- [ ] Models in `models/` (if needed beyond global models)
- [ ] Service dependencies injected (not instantiated in widget)
- [ ] `const` used for all immutable widgets
- [ ] Dispose callbacks for listeners/streams
- [ ] Theme colors/spacing used (no hardcoded values)
- [ ] Navigation route added to `main.dart`

## Template: New Screen

```dart
import 'package:flutter/material.dart';
import 'package:your_app/services/ble_service.dart';  // or other service
import 'package:your_app/core/theme/app_theme.dart';

class YourFeatureScreen extends StatefulWidget {
  const YourFeatureScreen({Key? key}) : super(key: key);

  @override
  State<YourFeatureScreen> createState() => _YourFeatureScreenState();
}

class _YourFeatureScreenState extends State<YourFeatureScreen> {
  late BleService _bleService;

  @override
  void initState() {
    super.initState();
    _bleService = BleService.instance;
    // Subscribe to streams if needed
  }

  @override
  void dispose() {
    // Clean up listeners/subscriptions
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Feature')),
      body: StreamBuilder(
        stream: _bleService.connectionState,
        builder: (context, snapshot) {
          // Build UI
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

## Service Integration Pattern

Always inject services, never instantiate in widgets:

```dart
// ✅ GOOD: Singleton via instance
final bleService = BleService.instance;
final drinkService = DrinkService.instance;

// ❌ AVOID: Direct instantiation
// final bleService = BleService();

// ✅ GOOD: Dependency injection for testing
class MyFeature {
  final BleService bleService;
  MyFeature({BleService? bleService}) 
    : bleService = bleService ?? BleService.instance;
}
```

## Navigation Integration

Add route to `main.dart`:

```dart
// In MaterialApp.router or routes map
GoRoute(
  path: '/your-feature',
  builder: (context, state) => const YourFeatureScreen(),
)
```

## Test Mode Compatibility

New features must work with `BleService.enableTestMode()`:

- Check: `BleService.isTestMode` to inject mock data
- Validate: Test mode still renders UI correctly
- Avoid: Features that break without real BLE connection

## Reusable Widget Checklist

If creating a new reusable component:

- [ ] Place in `widgets/` folder
- [ ] Use `const` constructor
- [ ] No direct BLE/service calls (pass data via parameters)
- [ ] Documented with example usage
- [ ] Handles null/empty states
- [ ] Respects theme colors/spacing

## Common Pitfalls

❌ **Pit 1**: Hardcoding colors instead of using theme  
✅ **Fix**: Use `AppTheme.colors.primary`, never `Color(0xFF...)`

❌ **Pit 2**: Not disposing streams/listeners  
✅ **Fix**: Always clean up in `dispose()` method

❌ **Pit 3**: Creating new service instances in widgets  
✅ **Fix**: Use `BleService.instance`, not `BleService()`

❌ **Pit 4**: Forgetting to test without hardware  
✅ **Fix**: Always verify feature works with `BleService.enableTestMode()`

❌ **Pit 5**: Duplicating UI components  
✅ **Fix**: Search existing features first, extract to `widgets/`

## Next Steps

1. Create feature folder structure
2. Build main screen using template
3. Extract reusable widgets to `widgets/`
4. Test with mock/test mode
5. Validate theme compliance with UI Consistency Skill
6. Add navigation route

## Project Context

- [lib/features/home/](../../../lib/features/home/) – home/connection pattern
- [lib/features/game/](../../../lib/features/game/) – complex game logic example
- [lib/services/ble_service.dart](../../../lib/services/ble_service.dart) – singleton pattern
- [lib/core/theme/](../../../lib/core/theme/) – theme definitions
