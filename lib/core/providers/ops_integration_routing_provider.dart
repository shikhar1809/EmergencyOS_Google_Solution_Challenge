import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../maps/maps_leaflet_fallback_provider.dart';
import '../../services/ops_integration_routing_service.dart';

/// Fleet-wide integration routing from Firestore (`ops_integration_routing/global`).
final opsIntegrationRoutingProvider = StreamProvider<OpsIntegrationRouting>((ref) {
  return OpsIntegrationRoutingService.watchGlobal();
});

/// True when maps should use Leaflet/OSM: **remote** `leaflet` **or** local auto-fallback (quota/auth).
final effectiveMapsUseLeafletProvider = Provider<bool>((ref) {
  final routing = ref.watch(opsIntegrationRoutingProvider).whenOrNull(data: (v) => v) ??
      OpsIntegrationRouting.defaults;
  final autoFallback = ref.watch(mapsLeafletFallbackProvider);
  if (autoFallback) return true;
  return routing.mapsTiles == OpsMapsTiles.leaflet;
});
