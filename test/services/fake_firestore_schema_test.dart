import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:emergency_os/services/incident_service.dart';

void main() {
  test('FakeFirebaseFirestore accepts sos_incidents document shape', () async {
    final fs = FakeFirebaseFirestore();
    final now = DateTime.now().toUtc();
    final inc = SosIncident(
      id: 'doc1',
      userId: 'u1',
      userDisplayName: 'User',
      location: const LatLng(0, 0),
      type: 'Rapid SOS',
      timestamp: now,
      goldenHourStart: now,
    );
    await fs.collection('sos_incidents').doc(inc.id).set(inc.toJson());
    final snap = await fs.collection('sos_incidents').doc('doc1').get();
    expect(snap.exists, isTrue);
    expect(snap.data()!['type'], 'Rapid SOS');
  });
}
