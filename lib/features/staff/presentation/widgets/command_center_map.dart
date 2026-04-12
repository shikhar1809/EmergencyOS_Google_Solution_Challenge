import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/google_maps_illustrative_light_style.dart';
import '../../../../core/maps/eos_hybrid_map.dart';
import '../../../../core/maps/ops_map_controller.dart';
import '../../../../core/constants/india_ops_zones.dart';
import '../../../../features/map/domain/emergency_zone_classification.dart';
class CommandCenterMap extends StatefulWidget {
  const CommandCenterMap({
    super.key,
    required this.zone,
    required this.markers,
    required this.polylines,
    required this.polygons,
    required this.showHexGrid,
    required this.initialPosition,
    required this.initialZoom,
    this.hexCoverRadiusM = kMaxCoverageRadiusM,
    this.hexCoverageCenter,
    this.overlayCircles = const <Circle>{},
    this.onMapCreated,
    this.onCameraMove,
    this.onTap,
    this.padding = EdgeInsets.zero,
  });

  final IndiaOpsZone zone;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  /// Approved safe-staging zones, fleet ETAs, etc. (always drawn).
  final Set<Circle> overlayCircles;
  final bool showHexGrid;
  final LatLng initialPosition;
  final double initialZoom;
  /// Matches [buildEmergencyHexZones] cover disk (admin command centre uses [kCommandCenterHexCoverRadiusM]).
  final double hexCoverRadiusM;
  /// When set (e.g. hospital console), the hex coverage ring is centered here instead of [zone.center].
  final LatLng? hexCoverageCenter;
  final ArgumentCallback<OpsMapController>? onMapCreated;
  final ArgumentCallback<CameraPosition>? onCameraMove;
  final ArgumentCallback<LatLng>? onTap;
  /// Inset for overlays (e.g. collapsible right detail panel).
  final EdgeInsets padding;

  @override
  State<CommandCenterMap> createState() => _CommandCenterMapState();
}

class _CommandCenterMapState extends State<CommandCenterMap> {
  @override
  Widget build(BuildContext context) {
    return EosHybridMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: widget.initialZoom,
      ),
      cameraTargetBounds: CameraTargetBounds(widget.zone.cameraBounds),
      minMaxZoomPreference: const MinMaxZoomPreference(5.5, 17),
      markers: widget.markers,
      polylines: widget.polylines,
      polygons: widget.polygons,
      circles: {
        ...widget.overlayCircles,
        if (widget.showHexGrid)
          Circle(
            circleId: const CircleId('admin_hex_cover_radius'),
            center: widget.hexCoverageCenter ?? widget.zone.center,
            radius: widget.hexCoverRadiusM,
            fillColor: Colors.transparent,
            strokeColor: const Color(0xFF37474F).withValues(alpha: 0.42),
            strokeWidth: 1,
            zIndex: 0,
          ),
      },
      mapType: MapType.normal,
      mapId: AppConstants.googleMapsDarkMapId.isNotEmpty
          ? AppConstants.googleMapsDarkMapId
          : null,
      style: effectiveGoogleMapsEmbeddedStyleJson(),
      zoomControlsEnabled: false,
      padding: widget.padding,
      onCameraMove: widget.onCameraMove,
      onMapCreated: widget.onMapCreated,
      onTap: widget.onTap,
    );
  }
}
