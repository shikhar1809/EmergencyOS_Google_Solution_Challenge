import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/map_marker_assets.dart';
import 'map_marker_generator.dart';

/// Preloaded **top-down vehicle** PNGs for fleet / operator units (not facility pins).
///
/// Five zoom tiers so icons scale proportionally with map zoom — tiny when
/// zoomed out to city level, comfortable when zoomed in to street level.
abstract final class FleetMapIcons {
  static final Map<int, BitmapDescriptor?> _ambulance = {};
  static bool _ready = false;

  /// Decode widths (logical px) — five tiers from city overview to street level.
  /// Further reduced so ambulances feel proportional to map labels.
  static const List<int> vehicleWidthTiers = [10, 14, 20, 28, 36];

  static bool get ready => _ready;

  /// Target bitmap width for the current map zoom.
  static int iconWidthForZoom(double? zoom) {
    final z = zoom ?? 12.0;
    if (z < 9.0) return vehicleWidthTiers[0];
    if (z < 11.0) return vehicleWidthTiers[1];
    if (z < 13.0) return vehicleWidthTiers[2];
    if (z < 15.0) return vehicleWidthTiers[3];
    return vehicleWidthTiers[4];
  }

  static bool zoomTierChanged(double? previousZoom, double newZoom) {
    return iconWidthForZoom(previousZoom) != iconWidthForZoom(newZoom);
  }

  static Future<void> preload() async {
    if (_ready) return;
    final fb = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    for (final w in vehicleWidthTiers) {
      _ambulance[w] ??= await MapMarkerGenerator.getAssetMarker(
        MapMarkerAssets.ambulance,
        width: w,
        fallback: fb,
      );
    }
    _ready = true;
  }

  static BitmapDescriptor _pick(Map<int, BitmapDescriptor?> m, double? zoom, BitmapDescriptor fallback) {
    final w = iconWidthForZoom(zoom);
    return m[w] ?? fallback;
  }

  static BitmapDescriptor ambulanceForZoom(double? zoom, BitmapDescriptor fallback) =>
      _pick(_ambulance, zoom, fallback);

  /// Default (mid zoom) — for call sites without camera tracking.
  static BitmapDescriptor ambulanceOr(BitmapDescriptor fallback) => ambulanceForZoom(null, fallback);
}
