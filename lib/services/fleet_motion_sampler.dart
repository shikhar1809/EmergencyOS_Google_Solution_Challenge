import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Samples **user** accelerometer (gravity removed) while a fleet unit is tracking.
/// RMS magnitude (m/s²) over each reporting window helps corroborate motion when GPS speed lags.
class FleetMotionSampler {
  StreamSubscription<UserAccelerometerEvent>? _sub;
  double _sumSq = 0;
  int _n = 0;

  bool get isRunning => _sub != null;

  void start() {
    if (kIsWeb) return;
    if (_sub != null) return;
    _sumSq = 0;
    _n = 0;
    _sub = userAccelerometerEventStream().listen(_onEvent, onError: (_) {});
  }

  void _onEvent(UserAccelerometerEvent e) {
    final m = e.x * e.x + e.y * e.y + e.z * e.z;
    _sumSq += m;
    _n++;
  }

  /// RMS magnitude √(mean(x²+y²+z²)) in m/s² since the last call; then resets accumulators.
  double? takeAccelRmsMs2() {
    if (_n == 0) return null;
    final meanSq = _sumSq / _n;
    _sumSq = 0;
    _n = 0;
    return math.sqrt(meanSq);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _sumSq = 0;
    _n = 0;
  }
}
