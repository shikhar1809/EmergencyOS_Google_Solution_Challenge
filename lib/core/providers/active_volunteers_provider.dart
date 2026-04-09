import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/volunteer_presence_service.dart';

/// Raw Firestore snapshots of users with `volunteerOnDuty == true` (limit 200).
final onDutyVolunteersSnapshotProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>(
  (_) => VolunteerPresenceService.watchOnDutyUsers(),
);
