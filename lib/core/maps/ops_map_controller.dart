import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'leaflet_map_runtime.dart';

/// Unified handle for programmatic camera moves whether the visible map is
/// Google or flutter_map (OSM tiles).
class OpsMapController {
  OpsMapController._(this._google, this._leafletRuntime)
      : assert(_google != null || _leafletRuntime != null);

  final GoogleMapController? _google;
  final LeafletMapRuntime? _leafletRuntime;

  factory OpsMapController.google(GoogleMapController c) =>
      OpsMapController._(c, null);

  factory OpsMapController.leaflet(LeafletMapRuntime runtime) =>
      OpsMapController._(null, runtime);

  bool get isGoogle => _google != null;

  void dispose() {
    _google?.dispose();
    // Leaflet [fm.MapController] lifecycle is owned by [EosHybridMap] state.
  }

  /// Best-effort parity with [GoogleMapController.animateCamera].
  Future<void> animateCamera(CameraUpdate update, {Duration? duration}) async {
    final g = _google;
    if (g != null) {
      await g.animateCamera(update, duration: duration);
      return;
    }
    final rt = _leafletRuntime;
    if (rt == null) return;
    final lc = rt.controller;

    if (update is CameraUpdateNewCameraPosition) {
      final cp = update.cameraPosition;
      lc.move(
        ll.LatLng(cp.target.latitude, cp.target.longitude),
        cp.zoom,
      );
      return;
    }
    if (update is CameraUpdateNewLatLng) {
      lc.move(
        ll.LatLng(update.latLng.latitude, update.latLng.longitude),
        rt.currentZoom,
      );
      return;
    }
    if (update is CameraUpdateNewLatLngZoom) {
      lc.move(
        ll.LatLng(update.latLng.latitude, update.latLng.longitude),
        update.zoom,
      );
      return;
    }
    if (update is CameraUpdateNewLatLngBounds) {
      final bounds = update.bounds;
      final sw = bounds.southwest;
      final ne = bounds.northeast;
      final fmBounds = fm.LatLngBounds(
        ll.LatLng(sw.latitude, sw.longitude),
        ll.LatLng(ne.latitude, ne.longitude),
      );
      lc.fitCamera(
        fm.CameraFit.bounds(
          bounds: fmBounds,
          padding: EdgeInsets.all(update.padding),
        ),
      );
      return;
    }
    if (update is CameraUpdateZoomIn) {
      lc.move(rt.currentCenter, (rt.currentZoom + 1).clamp(rt.minZoom, rt.maxZoom));
      return;
    }
    if (update is CameraUpdateZoomOut) {
      lc.move(rt.currentCenter, (rt.currentZoom - 1).clamp(rt.minZoom, rt.maxZoom));
      return;
    }
    if (update is CameraUpdateZoomTo) {
      lc.move(rt.currentCenter, update.zoom.clamp(rt.minZoom, rt.maxZoom));
    }
  }
}
