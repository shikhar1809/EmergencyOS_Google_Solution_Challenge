import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;

/// Live camera hints for [OpsMapController] when the OSM/flutter_map layer is active.
class LeafletMapRuntime {
  LeafletMapRuntime({
    required this.controller,
    required this.minZoom,
    required this.maxZoom,
    required ll.LatLng initialCenter,
    required double initialZoom,
  })  : currentCenter = initialCenter,
        currentZoom = initialZoom;

  final fm.MapController controller;
  final double minZoom;
  final double maxZoom;

  ll.LatLng currentCenter;
  double currentZoom;

  void onCamera(ll.LatLng center, double zoom) {
    currentCenter = center;
    currentZoom = zoom;
  }
}
