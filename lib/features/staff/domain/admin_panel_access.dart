import '../../../core/constants/demo_gate_password.dart';

/// Role-based scope for the desktop ops dashboard (codes verified client-side for demo).
enum AdminConsoleRole {
  master,
  medical,
}

/// Master-only: left column on the map screen — dedicated Management / Live Ops use separate rail tabs.
enum MasterCommandSidebarMode {
  /// Overview: map + filters + incident sidebar (active consignments, archive, vols, beds).
  none,
  /// Live fleet, on-duty volunteers, and hospital grid beside the map.
  liveOps,
}

/// Which tabs appear in the Overview incident sidebar.
enum AdminCommandTabKind {
  alerts,
  archive,
}

/// Session after the user enters the correct unique code(s) for their role.
class AdminPanelAccess {
  const AdminPanelAccess({
    required this.role,
    this.boundHospitalDocId,
  });

  final AdminConsoleRole role;
  /// Firestore `ops_hospitals` doc id (medical console hospital gate).
  final String? boundHospitalDocId;

  /// Demo gate password (`DEMO_GATE_PASSWORD` dart-define).
  static String get demoStationCode => DemoGatePassword.value;

  /// Command-centre analytics rail tab (Master + Medical).
  bool get canUseAnalytics =>
      role == AdminConsoleRole.master || role == AdminConsoleRole.medical;

  /// Post-incident feedback explorer — Master only.
  bool get canUseLiveOpsFeedback => role == AdminConsoleRole.master;

  /// Discord-style hospital ↔ incident voice comms (LiveKit).
  bool get canUseCommsBridge =>
      role == AdminConsoleRole.master || role == AdminConsoleRole.medical;

  bool get showHospitalUpdateRail =>
      role == AdminConsoleRole.master || role == AdminConsoleRole.medical;

  List<AdminCommandTabKind> get commandTabs =>
      const [AdminCommandTabKind.alerts, AdminCommandTabKind.archive];

  bool get showMapHospitals =>
      role == AdminConsoleRole.master || role == AdminConsoleRole.medical;
  bool get showMapVolunteers =>
      role == AdminConsoleRole.master || role == AdminConsoleRole.medical;

  /// `ops_fleet_units` docs visible on the command map for this role.
  bool isFleetDocVisible(Map<String, dynamic> data, String docId) {
    final vt = (data['vehicleType'] as String?)?.trim().toLowerCase() ?? 'medical';

    // Police / fire / crane / recovery fleet units removed product-wide — hide legacy Firestore rows.
    if (vt == 'police' || vt == 'fire' || vt == 'crane' || vt == 'recovery') return false;

    switch (role) {
      case AdminConsoleRole.master:
        return true;
      case AdminConsoleRole.medical:
        final hid = (boundHospitalDocId ?? '').trim();
        if (hid.isEmpty) {
          return vt == 'medical' || vt == 'ambulance';
        }
        // Hospital dashboard: ambulance/medical units assigned to this facility only.
        if (vt != 'medical' && vt != 'ambulance') return false;
        final ah = (data['assignedHospitalId'] as String?)?.trim() ?? '';
        final sh = (data['stationedHospitalId'] as String?)?.trim() ?? '';
        return ah == hid || sh == hid;
    }
  }

  /// Live unit markers embedded on incidents (`live_${id}_amb` style keys).
  bool isIncidentLiveFleetKeyAllowed(String mapKey) {
    switch (role) {
      case AdminConsoleRole.master:
        return true;
      case AdminConsoleRole.medical:
        return mapKey.contains('_amb');
    }
  }
}
