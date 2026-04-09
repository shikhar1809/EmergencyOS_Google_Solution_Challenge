# Contributing to EmergencyOS

Thank you for helping improve EmergencyOS.

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable channel).
2. Clone the repository and run `flutter pub get`.
3. Configure Firebase (`google-services.json` / `GoogleService-Info.plist` / web config) for your own project, or use the team’s shared dev project as documented internally.
4. Run `flutter analyze` and `flutter test` before opening a PR.

## Code style

- Follow [`flutter_lints`](analysis_options.yaml) defaults.
- Prefer `AppLocalizations` for user-visible strings; add keys in `lib/core/l10n/app_localizations.dart`.
- Document **public** classes and methods in `lib/services/**` and `lib/features/*/domain/**` with `///` dartdoc comments (see `docs/DARTDOC.md`).

## Pull requests

1. Branch from `master` / `main`.
2. Keep commits focused; reference issues if applicable.
3. Ensure CI checks pass: `flutter analyze`, `flutter test`.
4. Update `CHANGELOG.md` for user-facing or architectural changes.

## Security

Do not commit API keys, Firebase private keys, or production credentials. Use environment-specific config and secret managers.
