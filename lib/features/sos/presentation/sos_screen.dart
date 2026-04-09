import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/emergency_consent_dialog.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/incident_service.dart';
import '../../../services/offline_sos_status_service.dart';
import '../../../services/sms_gateway_service.dart';
import '../../../services/voice_comms_service.dart';
import 'sms_sos_screen.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  bool _isOffline = false;
  Timer? _holdTimer;
  Timer? _progressTimer;
  double _holdProgress = 0.0;
  bool _submitting = false;
  bool _pointerHolding = false;
  /// Web: 3s elapsed while holding — dispatch on pointer-up so speechSynthesis keeps user activation.
  bool _webAwaitReleaseToDispatch = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    setState(() => _isOffline = !ConnectivityService().isOnline);
  }


  void _startHold() {
    if (_submitting) return;
    _pointerHolding = true;
    _webAwaitReleaseToDispatch = false;
    VoiceCommsService.primeForVoiceGuidance();
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    setState(() => _holdProgress = 0.0);
    _holdTimer = Timer(const Duration(seconds: 3), () {
      if (!context.mounted) return;
      if (kIsWeb) {
        if (_pointerHolding) {
          setState(() {
            _holdProgress = 1.0;
            _webAwaitReleaseToDispatch = true;
          });
        }
        return;
      }
      _triggerHoldSos();
    });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!context.mounted) return;
      setState(() {
        _holdProgress += 0.02;
        if (_holdProgress > 1.0) _holdProgress = 1.0;
      });
    });
  }

  void _onPointerUp() {
    if (kIsWeb && _webAwaitReleaseToDispatch && !_submitting) {
      _webAwaitReleaseToDispatch = false;
      _pointerHolding = false;
      _holdTimer?.cancel();
      _progressTimer?.cancel();
      VoiceCommsService.primeForVoiceGuidance();
      _triggerHoldSos(fromWebReleaseGesture: true);
      if (context.mounted) setState(() => _holdProgress = 0.0);
      return;
    }
    _endHold();
  }

  void _endHold() {
    _pointerHolding = false;
    _webAwaitReleaseToDispatch = false;
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    if (!context.mounted) return;
    setState(() => _holdProgress = 0.0);
  }

  void _triggerHoldSos({bool fromWebReleaseGesture = false}) async {
    if (!fromWebReleaseGesture && !_pointerHolding) return;
    if (_submitting) return;
    _submitting = true;
    _progressTimer?.cancel();
    setState(() => _holdProgress = 1.0);

    final pinReady = await _ensureSosPinReady();
    if (!pinReady) {
      _submitting = false;
      if (kIsWeb) VoiceCommsService.discardSosVoicePriming();
      _endHold();
      return;
    }

    if (!context.mounted) return;
    final consented = await showEmergencyDataConsentIfNeeded(context);
    if (!consented) {
      _submitting = false;
      if (kIsWeb) VoiceCommsService.discardSosVoicePriming();
      _endHold();
      return;
    }

    String? createdId;
    try {
      final pos = await Geolocator.getCurrentPosition();
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'guest';
      final displayName = user?.displayName ??
          (user?.email?.split('@').first ?? user?.phoneNumber ?? 'Volunteer');
      final incident = await IncidentService.createIncident(
        userId: userId,
        userDisplayName: displayName,
        location: LatLng(pos.latitude, pos.longitude),
        type: 'Rapid SOS',
      );
      createdId = incident.id;

      unawaited(
        FirebaseFirestore.instance
            .collection('sos_incidents')
            .doc(createdId)
            .update({'requiredServices': const ['trauma']}),
      );

      ConnectivityService().start();
      unawaited(
        OfflineSosStatusService.markPendingIfOffline(
          incidentId: createdId,
          likelyOffline: !ConnectivityService().isOnline,
        ),
      );
      if (kIsWeb) {
        unawaited(
          SmsGatewayService.offerWebParallelGeoSmsIfNeeded(
            context,
            lat: pos.latitude,
            lng: pos.longitude,
            type: 'Rapid SOS',
            incidentId: createdId,
            victimCount: 1,
            freeText: 'EmergencyOS in-app SOS',
          ),
        );
      } else {
        unawaited(
          SmsGatewayService.tryOpenParallelGeoSmsRelay(
            lat: pos.latitude,
            lng: pos.longitude,
            type: 'Rapid SOS',
            incidentId: createdId,
            victimCount: 1,
            freeText: 'EmergencyOS in-app SOS',
          ),
        );
      }
      await IncidentService.persistActiveSos(createdId);
    } catch (e) {
      debugPrint('[SOS] SOS creation failed: $e');
      if (kIsWeb) VoiceCommsService.discardSosVoicePriming();
      if (context.mounted) {
        if (!ConnectivityService().isOnline) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SmsSosScreen()),
          );
        }
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l.sosFailedMessage(
                e is StateError ? (e.message) : l.sosCheckConnectionRetry,
              ),
            ),
            backgroundColor: AppColors.primaryDanger,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: l.sosRetry,
              textColor: Colors.white,
              onPressed: () => _triggerHoldSos(),
            ),
          ),
        );
      }
    }

    if (!context.mounted) return;
    if (createdId != null && createdId.isNotEmpty) {
      context.go('/sos-active/${Uri.encodeComponent(createdId)}');
      _submitting = false;
      return;
    }

    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.sosActiveFlowFailed),
        backgroundColor: AppColors.primaryDanger,
      ),
    );
    if (kIsWeb) VoiceCommsService.discardSosVoicePriming();
    _submitting = false;
    _endHold();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.sosScreenTitle, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryDanger.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 24, color: AppColors.primaryDanger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.sosHoldBanner,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // P2P Offline Mode Banner
            if (_isOffline)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                ),
                child: Row(children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.sosOfflineQueued,
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),
                ]),
              ),

            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: l.sosSemanticsHoldHint,
              child: Listener(
              onPointerDown: (_) => _startHold(),
              onPointerUp: (_) => _onPointerUp(),
              onPointerCancel: (_) => _endHold(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F0000), Color(0xFFD50000)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      l.sosHoldButton,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _holdProgress,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: Text(
                _submitting
                    ? l.sosStarting
                    : (kIsWeb && _webAwaitReleaseToDispatch)
                        ? l.sosReleaseToSend
                        : l.sosReleaseCancel,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _ensureSosPinReady() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) return true;

    final prefs = await SharedPreferences.getInstance();
    var hash = (prefs.getString('sos_pin_hash') ?? '').trim();
    if (hash.isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        hash = ((doc.data()?['sosPinHash'] as String?) ?? '').trim();
        if (hash.isNotEmpty) {
          await prefs.setString('sos_pin_hash', hash);
        }
      } catch (_) {}
    }
    if (hash.isNotEmpty) return true;
    if (!context.mounted) return false;

    final l = AppLocalizations.of(context);
    final goSet = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.setSosPinFirst, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(
          l.sosPinDispatchBody,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.later, style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDanger),
            child: Text(l.setPinNow),
          ),
        ],
      ),
    );
    if (goSet == true && context.mounted) {
      context.go('/profile');
    }
    return false;
  }
}
