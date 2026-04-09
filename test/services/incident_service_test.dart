import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:emergency_os/services/incident_service.dart';

void main() {
  group('SosIncident serialization', () {
    test('toJson contains required Firestore fields', () {
      final now = DateTime.utc(2025, 1, 15, 12, 0, 0);
      final inc = SosIncident(
        id: 'test-id',
        userId: 'u1',
        userDisplayName: 'Tester',
        location: const LatLng(26.84, 80.94),
        type: 'Rapid SOS',
        timestamp: now,
        goldenHourStart: now,
        acceptedVolunteerIds: const ['v1'],
        triage: const {'intakeCompleted': true},
      );
      final json = inc.toJson();
      expect(json['id'], 'test-id');
      expect(json['userId'], 'u1');
      expect(json['lat'], 26.84);
      expect(json['lng'], 80.94);
      expect(json['type'], 'Rapid SOS');
      expect(json['status'], 'pending');
      expect(json['acceptedVolunteerIds'], ['v1']);
      expect(json['triage'], isA<Map>());
    });

    test('fromJson round-trips toJson', () {
      final now = DateTime.utc(2025, 3, 1, 8, 30, 0);
      final original = SosIncident(
        id: 'roundtrip',
        userId: 'guest',
        userDisplayName: 'Guest',
        location: const LatLng(1.5, 2.5),
        type: 'Other medical emergency: fall',
        timestamp: now,
        goldenHourStart: now,
        bloodType: 'O+',
      );
      final restored = SosIncident.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.location.latitude, original.location.latitude);
      expect(restored.type, original.type);
      expect(restored.bloodType, 'O+');
    });
  });
}
