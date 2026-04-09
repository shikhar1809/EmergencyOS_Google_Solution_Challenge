import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefKey = 'eos_maps_leaflet_fallback';

/// When true, all [EosHybridMap] instances render OpenStreetMap tiles via
/// flutter_map (Leaflet-style) instead of Google Maps — used when the Google
/// Maps API fails (quota, auth, or load timeout).
class MapsLeafletFallbackNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  var _hydrated = false;

  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_kPrefKey) ?? false;
    if (v) state = true;
  }

  void activateLeaflet(String reason) {
    if (state) return;
    state = true;
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(_kPrefKey, true));
    debugPrint('[MapsFallback] Switching to OSM/Leaflet tiles: $reason');
  }

  /// Explicit preference (e.g. master clears auto-fallback when console maps = Google).
  void setLeafletExplicit(bool useLeaflet, {required String reason}) {
    state = useLeaflet;
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(_kPrefKey, useLeaflet));
    debugPrint(
      useLeaflet
          ? '[MapsFallback] Explicit OSM/Leaflet: $reason'
          : '[MapsFallback] Cleared OSM preference: $reason',
    );
  }
}

final mapsLeafletFallbackProvider =
    NotifierProvider<MapsLeafletFallbackNotifier, bool>(MapsLeafletFallbackNotifier.new);
