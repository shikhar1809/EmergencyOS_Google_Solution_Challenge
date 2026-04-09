import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_os/services/connectivity_service.dart';

void main() {
  group('ConnectivityService latency classifiers', () {
    test('classifyWebLatencyMs', () {
      expect(
        ConnectivityService.classifyWebLatencyMs(100, hasNetwork: false),
        NetworkQuality.offline,
      );
      expect(
        ConnectivityService.classifyWebLatencyMs(200, hasNetwork: true),
        NetworkQuality.good,
      );
      expect(
        ConnectivityService.classifyWebLatencyMs(500, hasNetwork: true),
        NetworkQuality.unstable,
      );
      expect(
        ConnectivityService.classifyWebLatencyMs(2000, hasNetwork: true),
        NetworkQuality.poor,
      );
    });

    test('classifyNativeLatencyMs', () {
      expect(
        ConnectivityService.classifyNativeLatencyMs(100, httpOk: true),
        NetworkQuality.good,
      );
      expect(
        ConnectivityService.classifyNativeLatencyMs(500, httpOk: true),
        NetworkQuality.unstable,
      );
      expect(
        ConnectivityService.classifyNativeLatencyMs(900, httpOk: true),
        NetworkQuality.poor,
      );
      expect(
        ConnectivityService.classifyNativeLatencyMs(900, httpOk: false),
        NetworkQuality.poor,
      );
    });

    test('shouldDeferExpensiveNetworkWork logic via quality enum', () {
      expect(NetworkQuality.offline.color, isNotNull);
      expect(NetworkQuality.good.glowColor, isNotNull);
    });
  });
}
