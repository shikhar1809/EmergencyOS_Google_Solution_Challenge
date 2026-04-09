import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Notifier implementation for global on-duty state (Riverpod 3.x compatible).
///
/// **Default ON** so volunteers receive SOS incident alerts without having to
/// find the dashboard toggle first. Persisted under [volunteer_on_duty].
class IsOnDutyNotifier extends Notifier<bool> {
  static const String _prefKey = 'volunteer_on_duty';

  @override
  bool build() {
    // Default ON; microtask syncs saved preference (usually same value).
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_prefKey) ?? true;
      if (state != v) state = v;
    });
    return true;
  }

  void toggle(bool value) {
    state = value;
    SharedPreferences.getInstance().then((p) => p.setBool(_prefKey, value));
  }
}

/// Global on-duty state provider.
final isOnDutyProvider = NotifierProvider<IsOnDutyNotifier, bool>(IsOnDutyNotifier.new);

/// Saves duty minutes to Firestore when the volunteer goes OFF duty.
Future<void> recordDutySession(DateTime dutyStartTime) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final elapsed = DateTime.now().difference(dutyStartTime).inMinutes;
  if (elapsed <= 0) return;

  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'dutyMinutes': FieldValue.increment(elapsed)},
      SetOptions(merge: true),
    );
  } catch (_) {}

  // Also persist locally as fallback
  final prefs = await SharedPreferences.getInstance();
  final prev = prefs.getInt('localDutyMinutes_$uid') ?? 0;
  await prefs.setInt('localDutyMinutes_$uid', prev + elapsed);
}
