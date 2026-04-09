import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_os/services/dispatch_chain_service.dart';

void main() {
  group('DispatchChainState', () {
    test('null assignment has status none', () {
      const state = DispatchChainState(null);
      expect(state.status, 'none');
      expect(state.currentTier, 1);
      expect(state.countdownSecondsRemaining, isNull);
      expect(state.isAccepted, isFalse);
      expect(state.isExhausted, isFalse);
      expect(state.isPendingAcceptance, isFalse);
      expect(state.phaseLabel, 'none');
      expect(state.currentHospitalName, '\u2014');
      expect(state.notifiedHospitalPosition, isNull);
      expect(state.acceptedHospitalPosition, isNull);
    });

    test('watchForIncident returns stream for empty id', () {
      final stream = DispatchChainService.watchForIncident('');
      expect(stream, isA<Stream<DispatchChainState>>());
    });

    test('watchForIncident returns stream for whitespace id', () {
      final stream = DispatchChainService.watchForIncident('   ');
      expect(stream, isA<Stream<DispatchChainState>>());
    });

    test('rawAssignmentDoc returns stream for empty id', () {
      final stream = DispatchChainService.rawAssignmentDoc('');
      expect(stream, isA<Stream>());
    });
  });
}
