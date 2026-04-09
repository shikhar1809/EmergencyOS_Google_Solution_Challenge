/// Compile-time feature toggles for EmergencyOS.
///
/// Inject via `--dart-define` when building, for example:
/// ```
/// flutter build web --release --dart-define=OPS_ZONE_ID=lucknow
/// ```
abstract final class BuildConfig {
  BuildConfig._();

  // ── Ops zone override ─────────────────────────────────────────────────────
  /// Override the default active ops zone for the command center.
  /// Must match an [IndiaOpsZones.all] id (e.g. 'lucknow', 'delhi_ncr').
  /// Empty string → Lucknow (pilot city default).
  ///
  /// Example: `--dart-define=OPS_ZONE_ID=delhi_ncr`
  static const String opsZoneId =
      String.fromEnvironment('OPS_ZONE_ID', defaultValue: '');
}
