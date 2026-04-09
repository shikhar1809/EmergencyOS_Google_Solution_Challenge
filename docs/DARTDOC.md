# Dart documentation policy

## Scope

All **public** classes, enums, typedefs, and top-level functions in:

- `lib/services/**/*.dart`  
- `lib/features/*/domain/**/*.dart`  

should have a **`///` dartdoc** comment that answers:

1. **What** the type is responsible for  
2. **Who** calls it (UI, Functions bridge, background service)  
3. **Side effects** (Firestore, GPS, mic, SMS) when non-obvious  

## Examples

```dart
/// Resolves emergency protocol steps from a free-text scenario description.
class ProtocolEngine {
  /// Returns the best-matching protocol id for [scenario].
  static String forScenario(String scenario) { ... }
}
```

## Tooling

Run `dart doc` from the project root to generate HTML API reference (optional CI step).

## Status

New and high-risk modules (`usage_analytics_service.dart`, connectivity, SOS escalation) are documented first; remaining files should be brought up incrementally—see `CONTRIBUTING.md`.
