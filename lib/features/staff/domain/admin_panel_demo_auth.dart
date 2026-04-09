/// Demo admin sign-in (Firebase Auth email/password).
/// Set at build: `--dart-define=DEMO_ADMIN_EMAIL=...` and `DEMO_ADMIN_PASSWORD=...`.
class AdminPanelDemoAuth {
  AdminPanelDemoAuth._();

  static const email = String.fromEnvironment('DEMO_ADMIN_EMAIL', defaultValue: '');
  static const password = String.fromEnvironment('DEMO_ADMIN_PASSWORD', defaultValue: '');
}
