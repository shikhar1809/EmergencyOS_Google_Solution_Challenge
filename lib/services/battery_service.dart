import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// EmergencyOS: BatteryService in lib/services/battery_service.dart.
class BatteryService {
  BatteryService._();
  static final _instance = BatteryService._();
  factory BatteryService() => _instance;

  int _level = 100;
  bool _isLowPower = false;
  Timer? _pollTimer;
  final _controller = StreamController<int>.broadcast();

  int get level => _level;
  bool get isLowPower => _isLowPower;
  Stream<int> get levelStream => _controller.stream;

  void start() {
    _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) => _poll());
    _poll();
  }

  Future<void> _poll() async {
    try {
      // Web: Battery Status API is not exposed here; report unavailable (-1), not a fake 100%.
      if (kIsWeb) {
        _level = -1;
        _isLowPower = false;
        _controller.add(_level);
        return;
      }
      _isLowPower = _level <= 15;
      _controller.add(_level);
    } catch (_) {
      _level = kIsWeb ? -1 : 100;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _controller.close();
  }
}

final batteryLevelProvider = StreamProvider<int>((ref) {
  final service = BatteryService();
  service.start();
  ref.onDispose(() => service.dispose());
  return service.levelStream;
});
