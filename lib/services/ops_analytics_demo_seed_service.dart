import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/india_ops_zones.dart';
import 'incident_service.dart';

/// Writes realistic demo rows to `sos_incidents` for admin analytics / command consoles.
/// Document IDs are stable per zone so re-seeding updates the same set.
///
/// Firestore create rule requires `userId == request.auth.uid`.
abstract final class OpsAnalyticsDemoSeedService {
  static const _prefix = 'demo_ops';

  // ── Real Lucknow hotspot pins ──────────────────────────────────────────────
  static const _lucknowHotspots = <(String, double, double)>[
    // (area name, lat, lng)
    ('Hazratganj Crossing', 26.8622, 80.9155),
    ('Gomti Nagar Sec-1', 26.8444, 81.0024),
    ('Alambagh Bus Stand', 26.8152, 80.9118),
    ('Aliganj Sector-C', 26.8997, 80.9535),
    ('Transport Nagar Gate-2', 26.8860, 80.8873),
    ('Chowk Mandir Marg', 26.8712, 80.9063),
    ('Aminabad Market', 26.8577, 80.9231),
    ('LDA Colony Ring Rd', 26.8300, 80.9562),
    ('Indira Nagar Kirloskar', 26.8775, 81.0018),
    ('Vikas Nagar Flyover', 26.8950, 80.9713),
    ('Mahanagar Parivartan Chowk', 26.8713, 80.9712),
    ('Rajajipuram Sec-7', 26.8398, 80.9103),
    ('Chinhat Bypass', 26.8300, 81.0562),
    ('Daliganj Bridge', 26.8811, 80.9218),
    ('Lucknow Railway Station', 26.9139, 80.9208),
    ('Gomti Nagar Ext.', 26.8202, 81.0352),
    ('Jankipuram Ext.', 26.9222, 80.9565),
    ('Sushant Golf City', 26.7985, 81.0022),
    ('Kapoorthala Chowk', 26.8605, 80.9835),
    ('Ashiana Chowk Flyover', 26.8031, 80.9412),
    ('Kursi Road Junction', 26.8850, 81.0312),
    ('Madiyaon Bazar', 26.9085, 80.9090),
    ('Faizabad Road NH-28', 26.9243, 81.0005),
    ('Sitapur Road Crossing', 26.9380, 80.9420),
    ('Raibareli Road Toll', 26.7850, 80.9710),
    ('Bijnaur Road Gate', 26.8432, 80.8832),
    ('Hussainganj Circle', 26.8650, 80.9120),
    ('Hazratganj GPO', 26.8544, 80.9211),
    ('Gomti Nagar M-Block', 26.8562, 81.0150),
    ('Sahara Ganj Mall', 26.8578, 80.9408),
    ('Nishatganj Market', 26.8842, 80.9232),
    ('Talkatora Stadium', 26.8705, 80.9055),
    ('Naka Hindola Crossing', 26.8480, 80.9562),
    ('Charbagh Railway Colony', 26.8550, 80.9110),
    ('Vishwas Khand 4 GN', 26.8415, 81.0210),
    ('Sector-8 Gomti Nagar', 26.8285, 80.9918),
    ('Priyadarsni Colony', 26.9145, 80.9733),
    ('Lucknow Zoo Road', 26.8604, 80.9303),
    ('Rajendra Nagar Sec-4', 26.8220, 80.9240),
    ('Telibagh Crossing', 26.7945, 80.9265),
    ('Manak Nagar Bridge', 26.8788, 80.9060),
    ('Aishbagh Mela Grounds', 26.8660, 80.9000),
    ('Takrohi Incl. Area', 26.8190, 81.0680),
    ('Sec-14 Indira Nagar', 26.8887, 80.9972),
    ('Hardoi Road Hospital', 26.9320, 80.9180),
    ('Cantonment Station', 26.8450, 80.9455),
    ('Sardar Patel Marg', 26.8522, 80.9342),
    ('Engineering College', 26.8701, 80.9572),
    ('Dewa Road Village', 26.8178, 80.8751),
    ('Gomti Riverfront', 26.8799, 80.9440),
    ('Medical College Road', 26.9065, 80.9512),
    ('Raja Bazar Crossing', 26.8725, 80.9180),
    ('Husainabad Clock Tower', 26.8764, 80.9025),
    ('Qaiserbagh Palace', 26.8680, 80.9160),
    ('New Hyderabad Colony', 26.8815, 80.9648),
    ('Sec-12 Alambagh', 26.8035, 80.9165),
    ('Papamau Bridge', 26.9502, 80.9820),
    ('Kakadev Sec-3', 26.8292, 80.9820),
    ('Indira Nagar Sec-7', 26.8841, 80.9879),
    ('Kalyanpur Crossing', 26.8961, 80.9222),
    ('Sarojini Nagar Market', 26.8260, 80.9430),
    ('Sector-1 Jankipuram', 26.9190, 80.9512),
    ('Kursi Road Nursery', 26.8920, 81.0218),
    ('Vrindavan Colony gate', 26.8100, 80.9605),
  ];

  static const _types = [
    'Cardiac Arrest',
    'Road Traffic Accident',
    'Fire Emergency',
    'Medical Emergency',
    'Choking',
    'Stroke',
    'Severe Bleeding',
    'Building Collapse',
    'Gas Leak',
    'Drowning',
    'Motorcycle Accident',
    'Pedestrian Hit',
    'Industrial Accident',
    'Electric Shock',
    'Fall from Height',
    'Poisoning',
    'Chest Pain',
    'Seizure',
    'Childbirth Emergency',
    'Burns Emergency',
  ];

  // Real Indian names for victim display names
  static const _victimNames = [
    'Rahul Verma', 'Priya Mishra', 'Arun Kumar Singh', 'Sunita Tiwari',
    'Manoj Yadav', 'Kavita Sharma', 'Deepak Gupta', 'Anjali Srivastava',
    'Vikram Pandey', 'Geeta Agarwal', 'Ramesh Bajpai', 'Pooja Dubey',
    'Sandeep Chauhan', 'Neha Jaiswal', 'Amit Trivedi', 'Reena Saxena',
    'Naresh Chandra', 'Seema Rawat', 'Ajay Bhatnagar', 'Meenakshi Nath',
    'Suresh Maurya', 'Anita Kesarwani', 'Rajiv Rastogi', 'Preeti Awasthi',
    'Hemant Shukla', 'Saroj Pal', 'Gaurav Sahu', 'Nirmala Patel',
    'Vinod Mishra', 'Sarita Bhatt', 'Kiran Lal', 'Devendra Katiyar',
    'Lalita Singh', 'Pramod Kumar', 'Usha Dixit', 'Yogesh Rai',
    'Rekha Pathak', 'Mohit Dube', 'Savita Tripathi', 'Dinesh Misra',
    'Ruchita Kapoor', 'Anand Banerjee', 'Sudha Rani', 'Pankaj Tomar',
    'Madhuri Garg', 'Sunil Jatav', 'Namita Khanna', 'Ravi Kishore',
    'Archana Roy', 'Rajesh Pandey', 'Nisha Yadav', 'Bittu Sharma',
    'Manisha Dixit', 'Sanjay Saxena', 'Tanmay Joshi', 'Varsha Srivastava',
    'Pradeep Kesharwani', 'Swati Mishra', 'Akhilesh Singh', 'Madhu Trivedi',
    'Kapil Dev', 'Rina Rastogi', 'Ashish Pande', 'Shakuntala Devi',
  ];

  // Demo volunteer IDs (demo prefix only — real accounts untouched)
  static const _volunteerIds = [
    'vol_demo_A', 'vol_demo_B', 'vol_demo_C', 'vol_demo_D',
    'vol_demo_E', 'vol_demo_F', 'vol_demo_G', 'vol_demo_H',
  ];
  static const _volunteerNames = [
    'Arun Sharma', 'Priya Mishra', 'Vikram Singh', 'Deepa Tiwari',
    'Mohit Yadav', 'Kavita Verma', 'Suresh Gupta', 'Anjali Pandey',
  ];

  /// Returns number of documents written (batch commit).
  static Future<int> seedIncidentsForZone(IndiaOpsZone zone) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) {
      debugPrint('[OpsAnalyticsDemoSeedService] No signed-in user; skip seed.');
      return 0;
    }

    final db = FirebaseFirestore.instance;
    final rand = math.Random(zone.id.hashCode ^ 0x5eed);
    final now = DateTime.now();
    var n = 0;

    // Lucknow has exactly 64 hotspots — use them all
    final spots = List.of(_lucknowHotspots);

    // Process in batches of 500 (Firestore limit)
    WriteBatch batch = db.batch();
    var batchCount = 0;

    for (var i = 0; i < 64; i++) {
      final spot = spots[i];
      final id = '${_prefix}_${zone.id}_$i';
      final type = _types[i % _types.length];
      final victimName = _victimNames[i % _victimNames.length];

      // Jitter each hotspot pin slightly (≤ 150 m) so pins don't all stack
      final jLat = (rand.nextDouble() - 0.5) * 0.0028;
      final jLng = (rand.nextDouble() - 0.5) * 0.0028;
      final pin = LatLng(spot.$2 + jLat, spot.$3 + jLng);

      if (!zone.containsLatLng(pin)) continue;

      // Spread timestamps across last 72 hours (older incidents first)
      final hoursAgo = (i * 1.1 + rand.nextDouble() * 0.8).ceil();
      final minsAgo  = rand.nextInt(55);
      final ts = now.subtract(Duration(hours: hoursAgo, minutes: minsAgo));

      IncidentStatus status;
      String? emsPhase;
      double? ambLat, ambLng, ambHdg;
      DateTime? ambUpd;
      List<String> volAcc = [];
      List<String> volScene = [];
      Map<String, String> responderNames = {};
      Map<String, dynamic>? triage;
      bool sms = false;
      String? ambulanceEta;

      switch (i % 11) {
        // ── Resolved ────────────────────────────────────────────────────────
        case 0:
        case 1:
          status = IncidentStatus.resolved;
          emsPhase = 'on_scene';
          break;

        // ── Pending (just triggered) ────────────────────────────────────────
        case 2:
        case 3:
        case 4:
          status = IncidentStatus.pending;
          emsPhase = null;
          triage = {
            'category': i % 3 == 0 ? 'Urgent' : 'Immediate',
            'severityScore': 42 + rand.nextInt(40),
            'severityFlags': <String>[if (i % 2 == 0) 'chest_pain' else 'trauma'],
            'notes': i % 2 == 0 ? 'Victim conscious, BP dropping' : 'Multiple injuries, road collision',
          };
          break;

        // ── Dispatched — ambulance + optional co-response ───────────────────
        case 5:
        case 6:
        case 7:
        case 8:
          status = IncidentStatus.dispatched;
          emsPhase = 'inbound';
          final etaMins = 5 + rand.nextInt(12);
          ambulanceEta = '~$etaMins min';

          // Place ambulance 0.8–2 km out on logical road bearing
          final dOff = 0.008 + rand.nextDouble() * 0.012;
          final angle = rand.nextDouble() * 2 * math.pi;
          ambLat = pin.latitude + math.sin(angle) * dOff;
          ambLng = pin.longitude + math.cos(angle) * dOff;
          ambUpd = now.subtract(Duration(minutes: 1 + rand.nextInt(8)));
          // Heading toward the incident pin
          ambHdg = _bearingTo(ambLat, ambLng, pin.latitude, pin.longitude);

          // Assign 1–3 demo volunteers
          final vCount = 1 + (i % 3);
          for (var v = 0; v < vCount; v++) {
            final vid = _volunteerIds[(i + v) % _volunteerIds.length];
            volAcc.add(vid);
            responderNames[vid] = _volunteerNames[(i + v) % _volunteerNames.length];
          }
          triage = {
            'category': 'Critical',
            'severityScore': 55 + rand.nextInt(35),
            'severityFlags': <String>['high_priority'],
            'notes': 'Bystander CPR ongoing, EMS ETA $etaMins min',
          };
          break;

        // ── Dispatched — on-scene ───────────────────────────────────────────
        case 9:
          status = IncidentStatus.dispatched;
          emsPhase = 'on_scene';
          ambLat = pin.latitude - 0.0005;
          ambLng = pin.longitude + 0.0005;
          ambUpd = now.subtract(const Duration(minutes: 4));
          ambHdg = _bearingTo(ambLat, ambLng, pin.latitude, pin.longitude);
          ambulanceEta = 'On scene';
          final leadVid = _volunteerIds[i % _volunteerIds.length];
          volAcc = [leadVid];
          volScene = [leadVid];
          responderNames = {leadVid: _volunteerNames[i % _volunteerNames.length]};
          break;

        // ── Blocked / SMS relay ─────────────────────────────────────────────
        default:
          status = IncidentStatus.blocked;
          sms = true;
      }

      if (i % 13 == 0) sms = true;

      final volLat = volAcc.isNotEmpty ? pin.latitude + 0.003 + rand.nextDouble() * 0.004 : null;
      final volLng = volAcc.isNotEmpty ? pin.longitude - 0.002 - rand.nextDouble() * 0.003 : null;

      final inc = SosIncident(
        id: id,
        userId: uid,
        userDisplayName: '$victimName · ${spot.$1}',
        location: pin,
        type: type,
        timestamp: ts,
        goldenHourStart: ts,
        status: status,
        bloodType: i % 3 == 0 ? ['O+', 'A+', 'B+', 'AB+', 'O-'][i % 5] : null,
        ambulanceEta: ambulanceEta,
        acceptedVolunteerIds: volAcc,
        ambulanceLiveLat: ambLat,
        ambulanceLiveLng: ambLng,
        ambulanceLiveUpdatedAt: ambUpd,
        ambulanceLiveHeadingDeg: ambHdg,
        adminDispatchNote: i % 7 == 0 ? 'Priority corridor clear — Medivac route active.' : null,
        smsOrigin: sms && i % 2 == 0,
        smsRelayReceived: sms && i % 2 == 1,
        emsWorkflowPhase: emsPhase,
        emsAcceptedAt: emsPhase != null ? ts.add(const Duration(minutes: 3)) : null,
        emsAcceptedBy: emsPhase != null ? 'ems_demo_uid' : null,
        emsOnSceneAt: emsPhase == 'on_scene' ? ts.add(const Duration(minutes: 18)) : null,
        volunteerLat: volLat,
        volunteerLng: volLng,
        volunteerUpdatedAt:
            volLat != null ? now.subtract(Duration(minutes: rand.nextInt(15))) : null,
        lastKnownLat: i % 5 == 0 ? pin.latitude + 0.0002 : null,
        lastKnownLng: i % 5 == 0 ? pin.longitude - 0.00015 : null,
        lastLocationAt:
            i % 5 == 0 ? now.subtract(const Duration(minutes: 2)) : null,
        onSceneVolunteerIds: volScene,
        responderNames: responderNames,
        triage: triage,
      );

      batch.set(db.collection('sos_incidents').doc(id), inc.toJson());
      n++;
      batchCount++;

      if (batchCount >= 490) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) await batch.commit();
    return n;
  }

  /// Compass bearing in degrees from (lat1,lng1) → (lat2,lng2).
  static double _bearingTo(double lat1, double lng1, double lat2, double lng2) {
    final l1 = lat1 * math.pi / 180;
    final l2 = lat2 * math.pi / 180;
    final dl = (lng2 - lng1) * math.pi / 180;
    final y = math.sin(dl) * math.cos(l2);
    final x = math.cos(l1) * math.sin(l2) - math.sin(l1) * math.cos(l2) * math.cos(dl);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
}
