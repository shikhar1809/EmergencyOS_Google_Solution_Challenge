import '../domain/admin_panel_access.dart';

/// Admin hosting URLs: master vs hospital consoles.
abstract final class OpsAdminRoutes {
  static const masterDashboard = '/master-dashboard';
  static const hospitalDashboard = '/hospital-dashboard';

  static String pathForRole(AdminConsoleRole r) =>
      r == AdminConsoleRole.medical ? hospitalDashboard : masterDashboard;

  static bool pathPrefersMedicalGate(String path) =>
      path.contains('hospital-dashboard');
}
