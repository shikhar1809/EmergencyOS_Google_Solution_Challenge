import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'maps_google_failure_bridge.dart';
import 'maps_leaflet_fallback_provider.dart';

/// Loads persisted fallback preference and wires web Google Maps auth failures.
class MapsFallbackBootstrap extends ConsumerStatefulWidget {
  const MapsFallbackBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MapsFallbackBootstrap> createState() => _MapsFallbackBootstrapState();
}

class _MapsFallbackBootstrapState extends ConsumerState<MapsFallbackBootstrap> {
  static var _webHooked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(mapsLeafletFallbackProvider.notifier).hydrate();
      if (!mounted) return;
      ref.read(mapsLeafletFallbackProvider.notifier).setLeafletExplicit(
            true,
            reason: 'opensource_default',
          );
    });
    if (kIsWeb && !_webHooked) {
      _webHooked = true;
      registerGoogleMapsWebFailureBridge((reason) {
        ref.read(mapsLeafletFallbackProvider.notifier).activateLeaflet(reason);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
