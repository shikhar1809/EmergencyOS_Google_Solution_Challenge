import 'maps_google_failure_bridge_stub.dart'
    if (dart.library.js_interop) 'maps_google_failure_bridge_web.dart';

/// Register a one-shot listener for Google Maps web failures (e.g. [gm_authFailure]).
void registerGoogleMapsWebFailureBridge(void Function(String reason) onFailure) {
  registerGoogleMapsWebFailureBridgeImpl(onFailure);
}
