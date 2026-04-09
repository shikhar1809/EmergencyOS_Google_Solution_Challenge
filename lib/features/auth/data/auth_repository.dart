import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/google_sign_in_native_config.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(
      clientId: kGoogleSignInWebClientId.isEmpty ? null : kGoogleSignInWebClientId,
    ),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _googleSignIn = googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web, use Firebase's signInWithPopup directly — the google_sign_in
        // package does not support web (it causes "Different origin" errors).
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // On native (Android/iOS), use the google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Phone Auth Variables
  String? _verificationId;

  Future<void> sendPhoneOTP(
    String phoneNumber, {
    required Function(String code) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      if (kIsWeb) {
        // Web: ConfirmationResult + reCAPTCHA (see main.dart initializeRecaptchaConfig).
        // Omit verifier: SDK uses an invisible reCAPTCHA (modal) with correct FirebaseAuthPlatform delegate.
        final ConfirmationResult result =
            await _auth.signInWithPhoneNumber(phoneNumber);
        _webConfirmationResult = result;
        onCodeSent(result.verificationId);
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            onError(e.message ?? 'Verification failed');
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            onCodeSent(verificationId);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  // Web-specific: holds the ConfirmationResult for phone auth
  ConfirmationResult? _webConfirmationResult;

  Future<UserCredential?> verifyPhoneOTP(String smsCode) async {
    try {
      if (kIsWeb) {
        if (_webConfirmationResult == null) throw Exception('Please request OTP first.');
        return await _webConfirmationResult!.confirm(smsCode);
      } else {
        if (_verificationId == null) throw Exception('Verification ID is null. Request OTP first.');
        final PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: smsCode,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
