import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_os/features/ai_assist/domain/protocol_engine.dart';

void main() {
  group('ProtocolEngine.forScenario', () {
    test('cardiac maps to CPR protocol', () {
      final p = ProtocolEngine.forScenario('Cardiac arrest');
      expect(p.id, 'cpr');
      expect(p.title, 'CPR Protocol');
      expect(p.steps, isNotEmpty);
    });

    test('bleeding maps to bleeding protocol', () {
      final p = ProtocolEngine.forScenario('Severe bleeding');
      expect(p.id, 'bleeding');
      expect(p.title, 'Severe Bleeding Protocol');
    });

    test('fire and smoke map to burns protocol', () {
      expect(ProtocolEngine.forScenario('House fire').id, 'burns');
      expect(ProtocolEngine.forScenario('smoke inhalation').id, 'burns');
    });

    test('drowning maps to airway protocol', () {
      expect(ProtocolEngine.forScenario('drowning victim').id, 'airway');
    });

    test('traffic accident maps to trauma protocol', () {
      expect(ProtocolEngine.forScenario('traffic collision').id, 'trauma');
      expect(ProtocolEngine.forScenario('vehicle accident').id, 'trauma');
    });

    test('unknown scenario maps to general protocol', () {
      final p = ProtocolEngine.forScenario('something else');
      expect(p.id, 'general');
      expect(p.title, 'General Emergency Protocol');
    });
  });
}
