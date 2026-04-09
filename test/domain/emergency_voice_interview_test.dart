import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_os/features/sos/domain/emergency_voice_interview_questions.dart';

void main() {
  group('EmergencyVoiceInterviewQuestions.bucketFor', () {
    test('normalizes medical strings', () {
      expect(EmergencyVoiceInterviewQuestions.bucketFor('Cardiac arrest'), 'cardiac');
      expect(EmergencyVoiceInterviewQuestions.bucketFor('severe BLEEDING'), 'bleeding');
      expect(EmergencyVoiceInterviewQuestions.bucketFor('anaphylaxis shock'), 'allergy');
      expect(EmergencyVoiceInterviewQuestions.bucketFor(null), 'generic');
    });

    test('normalizes fixed scenario labels', () {
      expect(EmergencyVoiceInterviewQuestions.bucketFor('Assault'), 'assault');
      expect(EmergencyVoiceInterviewQuestions.bucketFor('Hazard (fire)'), 'hazard');
      expect(EmergencyVoiceInterviewQuestions.bucketFor('Accident'), 'accident');
      expect(EmergencyVoiceInterviewQuestions.bucketFor('Medical'), 'medical');
    });
  });

  group('EmergencyVoiceInterviewQuestions.fixedInterviewFlow', () {
    test('always three chip questions', () {
      final flow = EmergencyVoiceInterviewQuestions.fixedInterviewFlow();
      expect(flow.length, 3);
      expect(flow.every((e) => e['type'] == 'chip'), isTrue);
      expect(flow[0]['key'], EmergencyVoiceInterviewQuestions.q1EmergencyTypeKey);
      expect(flow[1]['key'], EmergencyVoiceInterviewQuestions.q2SafetySeriousKey);
      expect(flow[2]['key'], EmergencyVoiceInterviewQuestions.q3PeopleCountKey);
    });

    test('flowForType matches fixed flow', () {
      expect(
        EmergencyVoiceInterviewQuestions.flowForType('anything'),
        EmergencyVoiceInterviewQuestions.fixedInterviewFlow(),
      );
    });
  });
}
