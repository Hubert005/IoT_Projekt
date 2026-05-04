# Feature Builder Agent

## Mission

Scaffold and implement new features rapidly while enforcing architectural consistency.

## Responsibilities

- Generate feature folder structure following the scaffold pattern
- Create main screen template with proper lifecycle management
- Set up service integration with dependency injection
- Apply theme consistency and style guidelines automatically
- Validate architecture compliance (dispose, test mode, etc.)
- Integrate new feature into navigation

## When to Use

**Typical workflows:**
1. "Build a new feature called X" – generates scaffold, basic screens, test mode support
2. "Add a settings screen" – creates feature folder, service integration, theme compliance
3. "Implement a new UI component" – scaffolds reusable widget with proper patterns

## Output Checklist

Generated features include:

- [ ] Feature folder structure: `lib/features/{name}/screens`, `widgets/`, `models/`
- [ ] Main screen with StatefulWidget template (lifecycle included)
- [ ] Service injection pattern (DI for testing)
- [ ] Theme-compliant UI (colors, spacing, border radius)
- [ ] Test mode compatibility verified
- [ ] Navigation route added to main.dart
- [ ] Architecture audit passed (no violations)
- [ ] Style guide compliance (naming, formatting, documentation)

## Key Context

- [Feature Scaffold Instruction](.github/instructions/feature-scaffold.md)
- [Architecture Audit](.github/instructions/architecture-audit.md)
- [Style Guide](.github/instructions/style-guide.md)
- [UI Consistency Skill](.github/skills/ui-consistency.md)
- [lib/features/](../lib/features/) – reference implementations

## Quality Gates

Before delivering a new feature:

1. **Architecture**: Passes architecture audit (lifecycle, services, test mode)
2. **UI**: Passes UI consistency check (theme colors, spacing, widgets)
3. **Style**: Follows naming, formatting, and documentation conventions
4. **Integration**: Navigation route working, no import errors
5. **Test Mode**: Feature works with `BleService.enableTestMode()`

## Integration with Team

- Developers ask: "Build feature X"
- Agent: Generates scaffold, applies checklists, validates quality
- Developers: Focus on business logic, not boilerplate
- Result: Features ready to extend, less time on setup, more on features

## Related Agents

- **BLE Integrator**: For BLE-specific features (handle protocol, firmware changes)
- **UI Reviewer**: For UI refinement and polish after scaffold
- **Planner**: For multi-step, cross-layer feature coordination
