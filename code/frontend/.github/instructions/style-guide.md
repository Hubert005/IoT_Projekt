# Style Guide Instruction

Maintain consistency in naming, code formatting, and BLE parsing across the team.

## Naming Conventions

### Folders & Files

| Type | Pattern | Example |
|------|---------|---------|
| Feature folder | `lowercase` | `lib/features/home/`, `lib/features/game/` |
| Feature screen | `{feature}_screen.dart` | `home_screen.dart`, `game_screen.dart` |
| Widget file | `{widget_name}.dart` | `my_card.dart`, `game_button.dart` |
| Model file | `{model_name}.dart` | `gesture.dart`, `drink.dart` |
| Service file | `{service}_service.dart` | `ble_service.dart`, `drink_service.dart` |

### Classes

| Type | Pattern | Example |
|------|---------|---------|
| Widget class | `PascalCase` | `class HomePage`, `class GameCard` |
| Service class | `PascalCase` | `class BleService`, `class DrinkService` |
| Model/Enum | `PascalCase` | `enum Gesture`, `class RoundResult` |
| Provider (if used) | `{name}Provider` | `gameProvider`, `settingsProvider` |

### Variables & Methods

| Type | Pattern | Example |
|------|---------|---------|
| Local variable | `camelCase` | `final myString = 'hello'` |
| Method | `camelCase` | `void startGame()`, `String parseMessage()` |
| Private variable | `_camelCase` | `final _controller = StreamController()` |
| Constants | `camelCase` | `const maxRounds = 3` |
| BLE commands | `lowercase_snake` | `'start'`, `'runde_1_0_2'` |

### Examples

```dart
// ✅ GOOD: Consistent naming
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BleService _bleService;
  final _roundController = TextEditingController();

  void _startGame() {
    // Implementation
  }
}

// ❌ BAD: Inconsistent naming
class game_Screen extends StatefulWidget {
  // Wrong: snake_case for class name
  late BleService BleService_instance;  // Wrong: inconsistent naming
  final controller = TextEditingController();  // Wrong: not prefixed with _

  void startGame() {  // Should be _startGame if private
    // Implementation
  }
}
```

## Formatting Rules

All code must follow `dart format` output:

```bash
dart format .
```

### Key Rules

- **Indentation**: 2 spaces (Flutter standard)
- **Line length**: Target 80 chars, max 100
- **Trailing commas**: Use in multi-line lists/args
- **Imports**: Group by package, then relative
- **Spacing**: 1 blank line between methods

### Example

```dart
import 'package:flutter/material.dart';

import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/services/ble_service.dart';

class MyWidget extends StatefulWidget {
  final String title;

  const MyWidget({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _sub = BleService.instance.connectionState.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
```

## BLE String Parsing Standard

**Always apply**:

### Rule 1: Trim Before Parse
```dart
// ❌ BAD
final parts = message.split('_');

// ✅ GOOD
final parts = message.trim().split('_');
```

### Rule 2: Validate Length
```dart
// ❌ BAD
final parts = message.trim().split('_');
final round = int.parse(parts[1]);  // Could crash if missing

// ✅ GOOD
final parts = message.trim().split('_');
if (parts.length < 3) {
  print('Invalid message format: $message');
  return;
}
final round = int.parse(parts[1]);
```

### Rule 3: Null-Safe Parsing
```dart
// ❌ BAD
final value = int.parse(parts[2]);  // Throws if invalid

// ✅ GOOD
final value = int.tryParse(parts[2]) ?? 0;
```

### Rule 4: Consistent Command Handling
```dart
// ✅ GOOD: Clear message type handling
void _handleMessage(String message) {
  final trimmed = message.trim();

  if (trimmed == 'start_ok') {
    _onStartOk();
  } else if (trimmed.startsWith('runde_')) {
    _onRundeMessage(trimmed);
  } else if (trimmed.startsWith('mix_')) {
    _onMixMessage(trimmed);
  } else {
    print('Unknown message: $trimmed');
  }
}

void _onRundeMessage(String message) {
  final parts = message.split('_');
  if (parts.length < 4) return;

  final roundNum = int.tryParse(parts[1]) ?? 0;
  final gesture1 = int.tryParse(parts[2]) ?? 0;
  final gesture2 = int.tryParse(parts[3]) ?? 0;

  // Process round
}
```

## Documentation Conventions

### Comments

- **Method comments**: Explain *why*, not *what*
- **Complex logic**: Add inline comments
- **BLE protocol**: Reference message format
- **Avoid**: Obvious comments on simple code

```dart
// ✅ GOOD
void _handleConnectionLoss() {
  // Retry with exponential backoff to avoid overwhelming the device
  // Max 5 retries, 1s, 2s, 4s, 8s, 16s
  _retryCount++;
}

// ❌ BAD
void _handleConnectionLoss() {
  // Handle connection loss
  _retryCount++;
}
```

### BLE Messages

Document protocol in code:

```dart
/// Sends a round result to the ESP32.
/// Format: "runde_{roundNumber}_{gesture1}_{gesture2}"
/// - roundNumber: 1-3 (round number)
/// - gesture1: 0=Rock, 1=Paper, 2=Scissors (P1)
/// - gesture2: 0=Rock, 1=Paper, 2=Scissors (P2)
void sendRunde(int round, Gesture g1, Gesture g2) {
  final message = 'runde_${round}_${g1.index}_${g2.index}';
  _bleService.send(message);
}
```

## Code Organization

### Widget Files
```dart
import 'package:flutter/material.dart';
// other imports

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Properties
  late StreamSubscription _sub;
  
  // Lifecycle
  @override
  void initState() { }

  @override
  void dispose() { }

  // Private methods
  void _privateMethod() { }

  // Build
  @override
  Widget build(BuildContext context) { }
}
```

### Service Files
```dart
class MyService {
  static final MyService _instance = MyService._internal();

  factory MyService() {
    return _instance;
  }

  MyService._internal();

  static MyService get instance => _instance;

  // Public API
  Stream<T> get state => _stateController.stream;

  void publicMethod() { }

  // Private implementation
  final _stateController = StreamController<T>();

  void _privateMethod() { }

  // Cleanup
  void dispose() {
    _stateController.close();
  }
}
```

## Common Style Violations

### ❌ Violation 1: Inconsistent Import Order
```dart
import 'package:my_app/services/ble_service.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
// Wrong: dart before other packages
```

✅ **Fix**: Group packages, then relative
```dart
import 'package:flutter/material.dart';

import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/services/ble_service.dart';
```

### ❌ Violation 2: Magic Numbers
```dart
SizedBox(height: 16);  // What is 16?
Padding(padding: EdgeInsets.all(12));  // Why 12?
```

✅ **Fix**: Use named constants
```dart
SizedBox(height: AppTheme.spacing.medium);
Padding(padding: EdgeInsets.all(AppTheme.spacing.standard));
```

### ❌ Violation 3: Unsafe BLE Parsing
```dart
final round = int.parse(parts[1]);  // Crashes if invalid
```

✅ **Fix**: Safe parsing with fallback
```dart
final round = int.tryParse(parts[1]) ?? 0;
```

## Team Checklist

Before committing code, verify:

- [ ] File names follow pattern (`{name}.dart`, `{feature}/`)
- [ ] Class names are `PascalCase`
- [ ] Private variables/methods start with `_`
- [ ] Public APIs are camelCase
- [ ] BLE messages parsed safely (trim, validate length, tryParse)
- [ ] No magic numbers (use theme constants)
- [ ] No hardcoded colors (use AppTheme)
- [ ] Code formatted: `dart format .`
- [ ] Imports grouped and sorted
- [ ] Comments explain *why*, not *what*

## Project Context

- [lib/core/theme/](../../../lib/core/theme/) – theme constants reference
- [lib/services/ble_service.dart](../../../lib/services/ble_service.dart) – service pattern
- [analysis_options.yaml](../../../analysis_options.yaml) – lint rules
- [README.md](../../../README.md) – BLE protocol specification
