import 'browser_detect_stub.dart'
    if (dart.library.html) 'browser_detect_impl.dart' as _impl;

/// Best-effort mobile browser detection for web OAuth behavior.
bool get isLikelyMobileWebBrowser => _impl.isLikelyMobileWebBrowser;
