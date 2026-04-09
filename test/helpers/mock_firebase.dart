import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// Returns an in-memory Firestore for unit tests (no [Firebase.initializeApp] required).
FakeFirebaseFirestore createFakeFirestore() => FakeFirebaseFirestore();
