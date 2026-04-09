import 'dart:html' as html;

/// True when the web app is running in a typical phone/tablet browser (not desktop).
bool get isLikelyMobileWebBrowser {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('android') ||
      ua.contains('mobile');
}
