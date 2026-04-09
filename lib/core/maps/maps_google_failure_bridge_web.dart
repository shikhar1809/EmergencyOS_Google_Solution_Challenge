import 'dart:html' as html;

void registerGoogleMapsWebFailureBridgeImpl(void Function(String reason) onFailure) {
  html.window.addEventListener('eos-google-maps-unavailable', (event) {
    var reason = 'web_event';
    if (event is html.CustomEvent) {
      final d = event.detail;
      if (d != null) reason = d.toString();
    }
    onFailure(reason);
  });
}
