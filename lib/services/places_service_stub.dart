import 'package:flutter/foundation.dart';

void getNearbyPlacesJsonImpl(
  double lat,
  double lng,
  String type,
  Function(String) callback,
) {
  debugPrint('[PlacesService] Stub called (non-web / test env).');
  callback('[]');
}
