import 'package:firebase_auth/firebase_auth.dart';

/// Flutter Web: [FirebaseAuth.getRedirectResult] is only meaningful once per redirect, and
/// in some browsers [UserCredential.user] is populated a tick before [FirebaseAuth.currentUser].
/// [main.dart] stores the redirect user here so splash, [GoRouter], and login can route reliably.
class WebAuthRedirectBridge {
  static User? _pending;

  static void setPendingUser(User? user) {
    _pending = user;
  }

  static void clearPending() {
    _pending = null;
  }

  static bool get hasPendingUser => _pending != null;

  /// Prefer [FirebaseAuth.currentUser]; fall back to the user captured from the last redirect.
  static User? resolvedUser(FirebaseAuth auth) {
    final cur = auth.currentUser;
    if (cur != null) {
      final p = _pending;
      if (p != null) {
        _pending = null;
      }
      return cur;
    }
    return _pending;
  }

}
