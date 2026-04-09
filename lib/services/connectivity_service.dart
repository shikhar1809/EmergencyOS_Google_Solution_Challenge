import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// EmergencyOS: NetworkQuality in lib/services/connectivity_service.dart.
enum NetworkQuality {
  offline,
  poor,
  unstable,
  good;

  Color get color {
    switch (this) {
      case NetworkQuality.offline: return const Color(0xFF616161);
      case NetworkQuality.poor: return const Color(0xFFFF1744);
      case NetworkQuality.unstable: return const Color(0xFFFF9100);
      case NetworkQuality.good: return const Color(0xFF00E676);
    }
  }

  Color get glowColor {
    switch (this) {
      case NetworkQuality.offline: return const Color(0x00616161);
      case NetworkQuality.poor: return const Color(0x66FF1744);
      case NetworkQuality.unstable: return const Color(0x55FF9100);
      case NetworkQuality.good: return const Color(0x4400E676);
    }
  }
}

/// EmergencyOS: ConnectivityService in lib/services/connectivity_service.dart.
class ConnectivityService {
  ConnectivityService._();
  static final _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;

  final _onlineController = StreamController<bool>.broadcast();
  final _qualityController = StreamController<NetworkQuality>.broadcast();

  bool _lastKnown = true;
  NetworkQuality _lastQuality = NetworkQuality.good;
  bool _emittedOnline = false;
  bool _emittedQuality = false;
  int _listenerCount = 0;
  bool _started = false;
  Timer? _pingTimer;
  StreamSubscription? _connectivitySub;

  bool get isOnline => _lastKnown;
  NetworkQuality get quality => _lastQuality;

  /// Prefer cache / reduce animation and background fetches (offline-first, low data).
  bool get shouldDeferExpensiveNetworkWork =>
      !isOnline ||
      _lastQuality == NetworkQuality.poor ||
      _lastQuality == NetworkQuality.unstable;

  /// Same thresholds as [_verifyWebConnectivity] after a successful HEAD.
  static NetworkQuality classifyWebLatencyMs(int ms, {required bool hasNetwork}) {
    if (!hasNetwork) return NetworkQuality.offline;
    if (ms < 400) return NetworkQuality.good;
    if (ms < 1000) return NetworkQuality.unstable;
    return NetworkQuality.poor;
  }

  /// Same thresholds as [_verifyWithPing] after a successful HTTP response.
  static NetworkQuality classifyNativeLatencyMs(int ms, {required bool httpOk}) {
    if (!httpOk) return NetworkQuality.poor;
    if (ms < 300) return NetworkQuality.good;
    if (ms < 800) return NetworkQuality.unstable;
    return NetworkQuality.poor;
  }
  Stream<bool> get onlineStream => _onlineController.stream;
  Stream<NetworkQuality> get qualityStream => _qualityController.stream;

  void start() {
    _listenerCount++;
    if (_started) return;
    _started = true;
    debugPrint('[Connectivity] Service Started (Listener Count: $_listenerCount)');

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) {
        _updateOnline(false);
        _updateQuality(NetworkQuality.offline);
      } else if (kIsWeb) {
        _verifyWebConnectivity();
      } else {
        _verifyWithPing();
      }
    });

    if (kIsWeb) {
      _verifyWebConnectivity();
      _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _verifyWebConnectivity());
    } else {
      _verifyWithPing();
      _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _verifyWithPing());
    }
  }

  void stop() {
    _listenerCount--;
    if (_listenerCount <= 0) {
      _listenerCount = 0; // Guard
      dispose();
    }
    debugPrint('[Connectivity] Service Stop Called (Remaining Listeners: $_listenerCount)');
  }

  Future<void> _verifyWebConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) {
        _updateOnline(false);
        _updateQuality(NetworkQuality.offline);
        return;
      }

      // Measure latency with a same-origin request (no CORS issues)
      final sw = Stopwatch()..start();
      try {
        await http.head(Uri.parse('${Uri.base.origin}/version.json'))
            .timeout(const Duration(seconds: 5));
        sw.stop();
        final ms = sw.elapsedMilliseconds;
        _updateOnline(true);
        _updateQuality(classifyWebLatencyMs(ms, hasNetwork: true));
      } catch (_) {
        _updateOnline(hasNetwork);
        _updateQuality(hasNetwork ? NetworkQuality.unstable : NetworkQuality.offline);
      }
    } catch (_) {
      _updateOnline(true);
      _updateQuality(NetworkQuality.good);
    }
  }

  Future<void> _verifyWithPing() async {
    final sw = Stopwatch()..start();
    try {
      final response = await http.get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 5));
      sw.stop();
      final ok = response.statusCode == 204 || response.statusCode == 200;
      _updateOnline(ok);
      if (!ok) {
        _updateQuality(NetworkQuality.poor);
      } else {
        final ms = sw.elapsedMilliseconds;
        _updateQuality(classifyNativeLatencyMs(ms, httpOk: true));
      }
    } catch (_) {
      _updateOnline(false);
      _updateQuality(NetworkQuality.offline);
    }
  }

  void _updateOnline(bool online) {
    if (online == _lastKnown && _emittedOnline) return;
    _lastKnown = online;
    _emittedOnline = true;
    _onlineController.add(online);
    debugPrint('[Connectivity] ${online ? "ONLINE" : "OFFLINE"}');
  }

  void _updateQuality(NetworkQuality q) {
    if (q == _lastQuality && _emittedQuality) return;
    final previous = _lastQuality;
    final hadPrior = _emittedQuality;
    _lastQuality = q;
    _emittedQuality = true;
    _qualityController.add(q);
    debugPrint('[Connectivity] Quality: ${q.name}');
    if (hadPrior && previous != q) {
      final msg = switch (q) {
        NetworkQuality.offline =>
          'You are offline. SOS and updates may be queued until connection returns.',
        NetworkQuality.poor => 'Connection is poor. Emergency features may be slower.',
        NetworkQuality.unstable => 'Connection is unstable.',
        NetworkQuality.good => 'Connection restored. Network quality is good.',
      };
      SemanticsService.announce(msg, TextDirection.ltr);
    }
  }

  void dispose() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _started = false;
    debugPrint('[Connectivity] Service Fully Disposed (No active listeners)');
  }
}

final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ConnectivityService();
  service.start();
  ref.onDispose(() => service.stop());
  return service.onlineStream;
});

final networkQualityProvider = StreamProvider<NetworkQuality>((ref) {
  final service = ConnectivityService();
  service.start();
  ref.onDispose(() => service.stop());
  return service.qualityStream;
});
