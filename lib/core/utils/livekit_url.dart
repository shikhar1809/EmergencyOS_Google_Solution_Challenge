/// LiveKit Flutter clients expect a WebSocket URL (`wss://` / `ws://`).
/// Cloud env vars are sometimes set with `https://`, which yields "invalid token" / connect failures.
abstract final class LivekitUrl {
  static String normalizeForClient(String url) {
    var u = url.trim();
    if (u.isEmpty) return u;
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.startsWith('https://')) {
      return 'wss://${u.substring(8)}';
    }
    if (u.startsWith('http://')) {
      return 'ws://${u.substring(7)}';
    }
    return u;
  }
}
