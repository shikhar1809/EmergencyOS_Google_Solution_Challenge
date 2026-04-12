import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/india_ops_zones.dart';
import '../../../../services/incident_service.dart';
import '../../domain/admin_panel_access.dart';
import 'command_center_incident_lists.dart';

class CommandCenterSidebar extends StatelessWidget {
  const CommandCenterSidebar({
    super.key,
    required this.access,
    required this.tabController,
    required this.filteredIncidents,
    required this.selectedId,
    required this.onIncidentTap,
    required this.onArchiveIncidentTap,
    required this.zone,
    required this.accent,
    this.priorityLabelFor,
    this.hospitalLocation,
  });

  final AdminPanelAccess access;
  final TabController tabController;
  final List<SosIncident> filteredIncidents;
  final String? selectedId;
  final Function(SosIncident) onIncidentTap;
  final void Function(SosIncident incident, String closureStatus) onArchiveIncidentTap;
  final IndiaOpsZone? zone;
  final Color accent;
  /// Returns P1–P4 dispatch priority label for sidebar rows.
  final String Function(SosIncident)? priorityLabelFor;
  /// When set (e.g. medical console), each row shows straight-line distance from this hospital to the scene pin.
  final LatLng? hospitalLocation;

  @override
  Widget build(BuildContext context) {
    final tabs = access.commandTabs;
    final fmt = DateFormat.MMMd().add_Hm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: accent,
          unselectedLabelColor: Colors.white38,
          indicatorColor: accent,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: tabs.map((k) => Tab(text: _commandTabTitle(k))).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: tabs.map((k) => _commandTabBody(k, filteredIncidents, fmt)).toList(),
          ),
        ),
      ],
    );
  }

  String _commandTabTitle(AdminCommandTabKind k) {
    return switch (k) {
      AdminCommandTabKind.alerts => 'Active alerts',
      AdminCommandTabKind.archive => 'Archive',
    };
  }

  Widget _commandTabBody(AdminCommandTabKind k, List<SosIncident> filtered, DateFormat fmt) {
    return switch (k) {
      AdminCommandTabKind.alerts => CommandCenterActiveIncidentList(
          filtered: filtered,
          selectedId: selectedId,
          onIncidentTap: onIncidentTap,
          accent: accent,
          priorityLabelFor: priorityLabelFor,
          hospitalLocation: hospitalLocation,
          boundHospitalDocId:
              access.role == AdminConsoleRole.medical ? access.boundHospitalDocId : null,
          zone: zone,
        ),
      AdminCommandTabKind.archive => CommandCenterArchiveIncidentList(
          selectedId: selectedId,
          onArchiveTap: onArchiveIncidentTap,
          accent: accent,
          zone: zone,
        ),
    };
  }
}
