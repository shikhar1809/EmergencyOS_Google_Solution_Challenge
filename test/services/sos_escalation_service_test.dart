import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_os/services/sos_escalation_service.dart';

void main() {
  group('SosEscalationService', () {
    test('fires tier2 at 60s and tier3 at 120s', () {
      fakeAsync((async) {
        var tier2 = false;
        var tier3 = false;
        final svc = SosEscalationService();
        svc.startEscalation(
          onTier2: () => tier2 = true,
          onTier3: () => tier3 = true,
        );

        async.elapse(const Duration(seconds: 59));
        expect(tier2, isFalse);
        async.elapse(const Duration(seconds: 1));
        expect(tier2, isTrue);
        expect(tier3, isFalse);

        async.elapse(const Duration(seconds: 59));
        expect(tier3, isFalse);
        async.elapse(const Duration(seconds: 1));
        expect(tier3, isTrue);

        svc.dispose();
      });
    });

    test('cancel prevents tier callbacks', () {
      fakeAsync((async) {
        var tier2 = false;
        var tier3 = false;
        final svc = SosEscalationService();
        svc.startEscalation(
          onTier2: () => tier2 = true,
          onTier3: () => tier3 = true,
        );
        async.elapse(const Duration(seconds: 30));
        svc.cancel();
        async.elapse(const Duration(seconds: 120));
        expect(tier2, isFalse);
        expect(tier3, isFalse);
        svc.dispose();
      });
    });
  });
}
