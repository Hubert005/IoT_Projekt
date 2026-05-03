# UI Consistency Skill

Use this skill to maintain design consistency, enforce theme usage, and validate widget patterns across the Flutter app.

## Focus

- **Theme Compliance**: Force theme colors, spacing, and border radius from `lib/core/theme/`
- **Widget Patterns**: Enforce reusable components, avoid duplicated UI logic
- **Consistency Checks**: Validate new UI against existing feature screens (home, game, recipes)

## Validation Rules

### Colors
- ❌ Never use `Color(0xFF...)` directly
- ✅ Use `AppTheme.colors.*` or `Theme.of(context)`
- Checklist: Search code for hardcoded colors before approval

### Spacing & Sizing
- ❌ Avoid magic numbers like `SizedBox(width: 16)` or `Padding(all: 12)`
- ✅ Use theme-defined constants: `AppTheme.spacing.*`, `AppTheme.radius.*`
- ✅ Use `const` where possible for performance

### Widget Reusability
- ❌ Don't duplicate button styles, input fields, cards
- ✅ Check `lib/features/` for similar UI patterns first
- ✅ Extract common widgets to `lib/core/widgets/` if missing

### Example Violations & Fixes

```dart
// ❌ BAD
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Color(0xFF1185FF),
    borderRadius: BorderRadius.circular(8),
  ),
)

// ✅ GOOD
Container(
  padding: EdgeInsets.all(AppTheme.spacing.medium),
  decoration: BoxDecoration(
    color: AppTheme.colors.primary,
    borderRadius: BorderRadius.circular(AppTheme.radius.standard),
  ),
)
```

## When to Apply

- Code review for new UI features
- When adding new screens or dialogs
- Before merging UI-related PRs
- As part of automated linting checks

## Project Context

- [lib/core/theme/](../../../lib/core/theme/) – centralized theme definitions
- [lib/features/home/](../../../lib/features/home/) – reference design for consistency
- [lib/features/game/](../../../lib/features/game/) – gaming UI patterns
- [lib/features/recipes/](../../../lib/features/recipes/) – list/detail UI pattern
