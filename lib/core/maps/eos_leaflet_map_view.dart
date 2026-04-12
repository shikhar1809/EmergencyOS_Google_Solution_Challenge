import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../theme/app_colors.dart';
import 'leaflet_map_runtime.dart';

/// Raster fallback when Google Maps is unavailable. Carto **dark_all**: dark basemap with readable
/// roads, aligned with the embedded emergency-response Google Maps style. Data © OpenStreetMap © CARTO.
const _kCartoDarkUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

const _kCartoSubdomains = ['a', 'b', 'c', 'd'];

int _eosFmInteractionFlags({
  required bool scrollGesturesEnabled,
  required bool zoomGesturesEnabled,
  required bool rotateGesturesEnabled,
}) {
  var f = fm.InteractiveFlag.none;
  if (scrollGesturesEnabled) {
    f |= fm.InteractiveFlag.drag |
        fm.InteractiveFlag.flingAnimation |
        fm.InteractiveFlag.pinchMove;
  }
  if (zoomGesturesEnabled) {
    f |= fm.InteractiveFlag.pinchZoom |
        fm.InteractiveFlag.doubleTapZoom |
        fm.InteractiveFlag.doubleTapDragZoom |
        fm.InteractiveFlag.scrollWheelZoom;
  }
  if (rotateGesturesEnabled) {
    f |= fm.InteractiveFlag.rotate;
  }
  return f;
}

fm.StrokePattern _googlePolylinePattern(List<PatternItem>? patterns) {
  if (patterns == null || patterns.isEmpty) {
    return const fm.StrokePattern.solid();
  }
  final segments = <double>[];
  for (final p in patterns) {
    if (identical(p, PatternItem.dot)) {
      segments.add(2);
      segments.add(4);
    } else if (p is VariableLengthPatternItem) {
      switch (p.type) {
        case PatternItemType.dash:
        case PatternItemType.gap:
          segments.add(p.length);
        case PatternItemType.dot:
          break;
      }
    }
  }
  if (segments.length >= 2 && segments.length % 2 == 0) {
    return fm.StrokePattern.dashed(segments: segments);
  }
  return const fm.StrokePattern.solid();
}

/// OpenStreetMap-backed map used when Google Maps is unavailable.
class EosLeafletMapView extends StatefulWidget {
  const EosLeafletMapView({
    super.key,
    required this.initialCameraPosition,
    required this.mapController,
    required this.runtime,
    this.onReady,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.polygons = const <Polygon>{},
    this.circles = const <Circle>{},
    this.cameraTargetBounds = CameraTargetBounds.unbounded,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
    this.padding = EdgeInsets.zero,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.onCameraMove,
    this.onTap,
    this.zoomControlsEnabled = false,
  });

  final CameraPosition initialCameraPosition;
  final fm.MapController mapController;
  final LeafletMapRuntime runtime;
  final VoidCallback? onReady;

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final Set<Circle> circles;
  final CameraTargetBounds cameraTargetBounds;
  final MinMaxZoomPreference minMaxZoomPreference;
  final EdgeInsets padding;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final CameraPositionCallback? onCameraMove;
  final ArgumentCallback<LatLng>? onTap;
  final bool zoomControlsEnabled;

  @override
  State<EosLeafletMapView> createState() => _EosLeafletMapViewState();
}

class _EosLeafletMapViewState extends State<EosLeafletMapView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady?.call());
  }

  fm.CameraConstraint? _cameraConstraint() {
    final b = widget.cameraTargetBounds.bounds;
    if (b == null) return null;
    final sw = b.southwest;
    final ne = b.northeast;
    return fm.CameraConstraint.contain(
      bounds: fm.LatLngBounds(
        ll.LatLng(sw.latitude, sw.longitude),
        ll.LatLng(ne.latitude, ne.longitude),
      ),
    );
  }

  (IconData, Color, double) _eosLeafletMarkerVisual(Marker m) {
    final id = m.markerId.value;
    if (id == 'amb') {
      return (Icons.medical_services_rounded, Colors.redAccent, 40);
    }
    if (m.flat) {
      return (Icons.navigation_rounded, AppColors.primaryInfo, 36);
    }
    if (id == 'user_location') {
      return (Icons.navigation_rounded, AppColors.primaryInfo, 36);
    }
    if (id.startsWith('sos_')) {
      return (Icons.crisis_alert_rounded, const Color(0xFFFF9100), 38);
    }
    if (id.startsWith('ops_hospital_') || id.startsWith('hospital_')) {
      return (Icons.local_hospital_rounded, const Color(0xFF26C6DA), 38);
    }
    if (id.startsWith('past_')) {
      return (Icons.history_rounded, AppColors.primaryWarning, 34);
    }
    return (Icons.place_rounded, AppColors.primaryDanger, 36);
  }

  List<fm.Marker> _fmMarkers() {
    return widget.markers.map((m) {
      final anchor = m.anchor;
      final alignment = fm.Marker.computePixelAlignment(
        width: 40,
        height: 40,
        left: anchor.dx * 40,
        top: anchor.dy * 40,
      );
      final vis = _eosLeafletMarkerVisual(m);
      Widget child = Icon(
        vis.$1,
        color: vis.$2,
        size: vis.$3,
      );
      if (m.rotation != 0) {
        child = Transform.rotate(
          angle: m.rotation * 3.141592653589793 / 180,
          child: child,
        );
      }
      final iwTitle = m.infoWindow.title;
      final snip = m.infoWindow.snippet;
      if ((iwTitle != null && iwTitle.isNotEmpty) || (snip != null && snip.isNotEmpty)) {
        child = Tooltip(
          message: [
            if (iwTitle != null && iwTitle.isNotEmpty) iwTitle,
            if (snip != null && snip.isNotEmpty) snip,
          ].join('\n'),
          child: child,
        );
      }
      return fm.Marker(
        point: ll.LatLng(m.position.latitude, m.position.longitude),
        width: 40,
        height: 40,
        alignment: alignment,
        child: GestureDetector(
          onTap: m.onTap,
          child: child,
        ),
      );
    }).toList();
  }

  List<fm.Polyline<Object?>> _fmPolylines() {
    return widget.polylines.map((pl) {
      return fm.Polyline(
        points: [
          for (final p in pl.points) ll.LatLng(p.latitude, p.longitude),
        ],
        strokeWidth: pl.width.toDouble(),
        color: pl.color,
        pattern: _googlePolylinePattern(pl.patterns),
      );
    }).toList();
  }

  List<fm.Polygon<Object?>> _fmPolygons() {
    return widget.polygons
        .where((pg) => pg.points.length >= 2)
        .map((pg) {
          return fm.Polygon(
            points: [for (final p in pg.points) ll.LatLng(p.latitude, p.longitude)],
            holePointsList: pg.holes.isEmpty
                ? null
                : [
                    for (final h in pg.holes)
                      [for (final p in h) ll.LatLng(p.latitude, p.longitude)],
                  ],
            color: pg.fillColor,
            borderStrokeWidth: pg.strokeWidth.toDouble(),
            borderColor: pg.strokeColor,
          );
        })
        .toList();
  }

  List<fm.CircleMarker<Object?>> _fmCircles() {
    return widget.circles.map((c) {
      return fm.CircleMarker(
        point: ll.LatLng(c.center.latitude, c.center.longitude),
        radius: c.radius,
        useRadiusInMeter: true,
        color: c.fillColor,
        borderStrokeWidth: c.strokeWidth.toDouble(),
        borderColor: c.strokeColor,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final minZ = widget.minMaxZoomPreference.minZoom ?? 2;
    final maxZ = widget.minMaxZoomPreference.maxZoom ?? 19;
    final init = widget.initialCameraPosition;
    final center = ll.LatLng(init.target.latitude, init.target.longitude);
    widget.runtime.currentCenter = center;
    widget.runtime.currentZoom = init.zoom;

    final interaction = _eosFmInteractionFlags(
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
    );

    Widget map = fm.FlutterMap(
      mapController: widget.mapController,
      options: fm.MapOptions(
        initialCenter: center,
        initialZoom: init.zoom,
        minZoom: minZ,
        maxZoom: maxZ,
        backgroundColor: const Color(0xFF0E1419),
        cameraConstraint: _cameraConstraint() ?? const fm.CameraConstraint.unconstrained(),
        interactionOptions: fm.InteractionOptions(flags: interaction),
        onPositionChanged: (camera, _) {
          widget.runtime.onCamera(camera.center, camera.zoom);
          widget.onCameraMove?.call(
            CameraPosition(
              target: LatLng(camera.center.latitude, camera.center.longitude),
              zoom: camera.zoom,
              bearing: camera.rotation,
              tilt: 0,
            ),
          );
        },
        onTap: widget.onTap == null
            ? null
            : (tapPos, latlng) {
                widget.onTap!(LatLng(latlng.latitude, latlng.longitude));
              },
      ),
      children: [
        fm.TileLayer(
          urlTemplate: _kCartoDarkUrl,
          subdomains: _kCartoSubdomains,
          userAgentPackageName: 'com.emergencyos.app',
          maxZoom: 20,
        ),
        if (_fmCircles().isNotEmpty) fm.CircleLayer<Object>(circles: _fmCircles().cast<fm.CircleMarker<Object>>()),
        if (_fmPolygons().isNotEmpty) fm.PolygonLayer<Object>(polygons: _fmPolygons().cast<fm.Polygon<Object>>()),
        if (_fmPolylines().isNotEmpty) fm.PolylineLayer<Object>(polylines: _fmPolylines().cast<fm.Polyline<Object>>()),
        if (_fmMarkers().isNotEmpty) fm.MarkerLayer(markers: _fmMarkers()),
        fm.SimpleAttributionWidget(
          source: Text(
            '© OpenStreetMap © CARTO',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF0E1419).withValues(alpha: 0.88),
          alignment: Alignment.bottomLeft,
        ),
      ],
    );

    if (widget.padding != EdgeInsets.zero) {
      map = Padding(padding: widget.padding, child: map);
    }

    if (!widget.zoomControlsEnabled) return map;

    return Stack(
      fit: StackFit.expand,
      children: [
        map,
        Positioned(
          right: 8,
          bottom: 48,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: AppColors.surfaceHighlight.withValues(alpha: 0.94),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.add, color: AppColors.textPrimary),
                  onPressed: () {
                    final r = widget.runtime;
                    widget.mapController.move(
                      r.currentCenter,
                      (r.currentZoom + 1).clamp(minZ, maxZ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Material(
                color: AppColors.surfaceHighlight.withValues(alpha: 0.94),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.remove, color: AppColors.textPrimary),
                  onPressed: () {
                    final r = widget.runtime;
                    widget.mapController.move(
                      r.currentCenter,
                      (r.currentZoom - 1).clamp(minZ, maxZ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
