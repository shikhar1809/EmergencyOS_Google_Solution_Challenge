import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/navigation/app_root_navigator_key.dart';

// ---------------------------------------------------------------------------
// FCM Volunteer Dispatch Service
// Registers device token, handles incoming SOS alerts
//
// Web VAPID key: Generate one in Firebase Console → Cloud Messaging → Web Push
// certificates. Set it below so web browsers can receive push notifications.
// ---------------------------------------------------------------------------

/// EmergencyOS: FcmService in lib/services/fcm_service.dart.
class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// TODO: PRODUCTION READINESS
  /// Generate one in Firebase Console → Project Settings → Cloud Messaging 
  /// → Web Push certificates → Key pair. Replace with YOUR project's VAPID key.
  /// Web push notifications will NOT work on browsers without this key.
  static const String _webVapidKey = '';

  static bool _listenersAttached = false;

  /// Opens deep links from notification tap (cold start + background).
  /// Falls back to [pendingIncidentId] when no path is present.
  static Future<void> applyOpenedNotificationNavigation(Map<String, dynamic> raw) async {
    final data = raw.map((k, v) => MapEntry(k.toString(), v));
    if (_isOwnSosData(data)) return;

    final prefer = (data['deepLinkPreferred'] ?? '').toString().trim();
    final cons = (data['deepLinkConsignment'] ?? '').toString().trim();
    final ptt = (data['deepLinkPtt'] ?? '').toString().trim();
    final sosActive = (data['deepLinkSosActive'] ?? '').toString().trim();

    String? path;
    if (prefer == 'ptt' && ptt.isNotEmpty) {
      path = ptt;
    } else if (prefer == 'sos_active' && sosActive.isNotEmpty) {
      path = sosActive;
    } else if (cons.isNotEmpty) {
      path = cons;
    } else if (ptt.isNotEmpty) {
      path = ptt;
    } else if (sosActive.isNotEmpty) {
      path = sosActive;
    }

    final ctx = appRootNavigatorKey.currentContext;
    if (path != null && path.isNotEmpty && ctx != null && ctx.mounted) {
      GoRouter.of(ctx).go(path);
      return;
    }

    final id = (data['incidentId'] ?? '').toString().trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingIncidentId', id);
  }

  /// True when this device belongs to the user who created the SOS (FCM data).
  static bool _isOwnSosData(Map<String, dynamic> data) {
    final reporter = (data['reportingUserId'] ?? '').toString().trim();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return reporter.isNotEmpty && uid.isNotEmpty && reporter == uid;
  }

  /// Call once after Firebase init + auth
  static Future<void> init(String userId) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
        criticalAlert: true,
      );
      final authStatus = settings.authorizationStatus;
      final now = DateTime.now().toIso8601String();
      if (userId.isNotEmpty) {
        await _db.collection('volunteers').doc(userId).set({
          'pushPlatform': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'pushAuthStatus': authStatus.name,
          'pushUpdatedAt': now,
        }, SetOptions(merge: true));
      }
      if (authStatus != AuthorizationStatus.authorized) return;

      // Get token — web may require VAPID key; mobile does not.
      String? token;
      try {
        if (kIsWeb && _webVapidKey.isNotEmpty) {
          token = await _messaging.getToken(vapidKey: _webVapidKey);
        } else {
          token = await _messaging.getToken();
        }
      } catch (e) {
        debugPrint('[FCM] getToken attempt 1 failed: $e');
        // Retry once after a short delay (transient network on cold start).
        await Future.delayed(const Duration(seconds: 2));
        try {
          if (kIsWeb && _webVapidKey.isNotEmpty) {
            token = await _messaging.getToken(vapidKey: _webVapidKey);
          } else {
            token = await _messaging.getToken();
          }
        } catch (e2) {
          debugPrint('[FCM] getToken attempt 2 failed: $e2');
          if (kIsWeb) {
            debugPrint('[FCM] ⚠️ Web push will NOT work. Generate a VAPID key in '
                'Firebase Console → Cloud Messaging → Web Push certificates '
                'and set _webVapidKey in fcm_service.dart');
          }
        }
      }

      if (token != null && userId.isNotEmpty) {
        final tokenPayload = {
          'fcmToken': token,
          'updatedAt': now,
        };
        try {
          await Future.wait([
            _db.collection('volunteers').doc(userId).set({
              ...tokenPayload,
              'online': true,
              'isAvailable': true,
            }, SetOptions(merge: true)),
            _db.collection('users').doc(userId).set({
              ...tokenPayload,
              'pushPlatform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            }, SetOptions(merge: true)),
          ]);
          debugPrint('[FCM] Token saved for $userId (${kIsWeb ? "web" : "mobile"})');
        } catch (e) {
          debugPrint('[FCM] Token save failed (will retry on next init): $e');
        }
      } else {
        debugPrint('[FCM] WARNING: No FCM token obtained — push notifications will NOT work.');
        debugPrint('[FCM] In-app Firestore real-time alerts are still active as primary fallback.');
      }

      // Topic subscription (mobile only — not supported on web).
      if (!kIsWeb) {
        try {
          await _messaging.subscribeToTopic('sos_alerts');
        } catch (e) {
          debugPrint('[FCM] Topic subscribe failed (non-fatal): $e');
        }
      }

      // Attach message listeners only once to avoid duplicate handlers.
      if (!_listenersAttached) {
        _listenersAttached = true;

        _messaging.onTokenRefresh.listen((newToken) async {
          final refreshPayload = {
            'fcmToken': newToken,
            'updatedAt': DateTime.now().toIso8601String(),
          };
          try {
            await Future.wait([
              _db.collection('volunteers').doc(userId).set({
                ...refreshPayload,
                'isAvailable': true,
              }, SetOptions(merge: true)),
              _db.collection('users').doc(userId).set(
                refreshPayload,
                SetOptions(merge: true),
              ),
            ]);
            debugPrint('[FCM] Token refreshed for $userId');
          } catch (_) {}
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleForegroundMessage(message);
        });

        FirebaseMessaging.onMessageOpenedApp.listen((message) async {
          await applyOpenedNotificationNavigation(message.data);
        });
      }

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        await applyOpenedNotificationNavigation(initial.data);
      }
    } catch (e) {
      debugPrint('[FCM] Init error (non-fatal): $e');
    }
  }

  static void Function(RemoteMessage)? _onMessageCallback;

  static void setOnMessageCallback(void Function(RemoteMessage) cb) {
    _onMessageCallback = cb;
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    if (_isOwnSosData(message.data)) return;
    _onMessageCallback?.call(message);
  }

  /// Mark volunteer offline on logout
  static Future<void> setOffline(String userId) async {
    try {
      await _db.collection('volunteers').doc(userId).update({'online': false});
    } catch (_) {}
  }
}

// ─── In-app SOS Alert Banner Widget ───────────────────────────────────────

/// EmergencyOS: SosAlertBanner in lib/services/fcm_service.dart.
class SosAlertBanner extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final VoidCallback? onRespond;

  const SosAlertBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onDismiss,
    this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
        ),
        child: Row(
          children: [
            const Icon(Icons.sos_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  Text(body, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            if (onRespond != null)
              TextButton(
                onPressed: onRespond,
                child: const Text('RESPOND', style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
              ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
