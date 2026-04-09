import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Normal raster map, no traffic, fewer overlays — for native mobile and
/// phone/tablet browsers where hybrid + traffic crashes or reloads WebKit.
bool useLowPowerGoogleMapLayer(BuildContext context) {
  if (!kIsWeb) {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
  return MediaQuery.sizeOf(context).shortestSide < 768;
}

/// Constant marker rotation via [AnimationController] + setState still stresses
/// Flutter Web + Maps; disable on mobile web only (native keeps throttled motion).
bool suppressGoogleMapMarkerAnimations(BuildContext context) {
  return kIsWeb && MediaQuery.sizeOf(context).shortestSide < 768;
}
