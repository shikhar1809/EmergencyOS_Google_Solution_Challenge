// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../services/incident_service.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../web_bridge/emergency_alarm.dart';
import 'volunteer_voice_mode_prompt.dart';

/// iPhone-style full-screen incoming emergency overlay with:
/// - Swipe-to-accept handle (must drag >85% of track width)
/// - Web Audio API alarm (via dart:js_interop) that loops until dismissed
class IncomingEmergencyOverlay extends StatefulWidget {
  final SosIncident incident;
  /// Practice from login: no Firestore accept; navigate to drill consignment.
  final bool isDrillPractice;
  const IncomingEmergencyOverlay({
    super.key,
    required this.incident,
    this.isDrillPractice = false,
  });

  @override
  State<IncomingEmergencyOverlay> createState() => _IncomingEmergencyOverlayState();
}

class _IncomingEmergencyOverlayState extends State<IncomingEmergencyOverlay>
    with SingleTickerProviderStateMixin {
  // Swipe state
  double _dragX = 0.0;
  bool _accepted = false;

  // Pulse animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _startAlarm();
  }

  void _startAlarm() {
    if (widget.isDrillPractice) return;
    emergencyAlarmStart();
  }

  void _stopAlarm() {
    emergencyAlarmStop();
  }

  void _deny() {
    _stopAlarm();
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _accept() async {
    if (_accepted) return;
    _accepted = true;
    _stopAlarm();

    final router = GoRouter.of(context);
    final incidentId = widget.incident.id.trim();
    final typeRaw =
        widget.incident.type.trim().isEmpty ? 'Emergency' : widget.incident.type.trim();

    if (widget.isDrillPractice) {
      if (!context.mounted) return;
      // For volunteer drill practice, still offer audio vs silent mode before opening consignment.
      await VolunteerVoiceModePrompt.show(context);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final drillId = AppConstants.drillIncidentId;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        router.go(
          '/active-consignment/${Uri.encodeComponent(drillId)}?drill=1&type=${Uri.encodeComponent('Training')}',
        );
      });
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (context.mounted) {
        setState(() {
          _accepted = false;
          _dragX = 0.0;
        });
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Sign in to accept alerts.'),
            backgroundColor: AppColors.primaryDanger,
          ),
        );
      }
      return;
    }

    try {
      // Must finish before navigation: Active Consignment listens to Firestore and will
      // clear prefs if acceptedVolunteerIds does not include this user yet (race → "page gone").
      await IncidentService.acceptIncident(incidentId, currentUser.uid);
      await IncidentService.persistVolunteerAssignment(
        incidentId: incidentId,
        incidentType: typeRaw,
      );
      if (!mounted) return;
      // After accept succeeds, let the volunteer pick audio vs silent guidance before mission view.
      await VolunteerVoiceModePrompt.show(context);
    } catch (e, st) {
      debugPrint('[IncomingEmergency] accept failed: $e\n$st');
      var msg = 'Could not accept this alert. Check your connection and try again.';
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          msg = 'Could not accept (access denied). If this keeps happening, the app rules may need updating.';
        } else if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
          msg = 'Network issue — check your connection and try again.';
        }
      }
      if (context.mounted) {
        setState(() {
          _accepted = false;
          _dragX = 0.0;
        });
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.primaryDanger,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
    final path =
        '/active-consignment/${Uri.encodeComponent(incidentId)}?type=${Uri.encodeComponent(typeRaw)}';
    // go() replaces stack cleanly on web; push() + shell routes was leaving users on a blank or wrong route.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      router.go(path);
    });
  }

  @override
  void dispose() {
    _stopAlarm();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _bgEmoji {
    final t = widget.incident.type.toLowerCase();
    if (t.contains('cardiac')) return '❤️';
    if (t.contains('fire')) return '🔥';
    if (t.contains('collision') || t.contains('accident')) return '🚗';
    if (t.contains('drowning')) return '🌊';
    return '🚨';
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final trackWidth = (screenW - 64.0).clamp(200.0, 400.0);
    const handleSize = 60.0;
    final maxDrag = trackWidth - handleSize;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) => Transform.scale(scale: _pulseAnim.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border.all(color: AppColors.primaryDanger, width: 3),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Icon circle
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDanger.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryDanger, width: 2),
                  ),
                  child: Text(_bgEmoji, style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isDrillPractice ? 'PRACTICE ALERT (DRILL)' : 'INCOMING EMERGENCY',
                  style: const TextStyle(
                    color: AppColors.primaryDanger,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.incident.type,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Reported by ${widget.incident.userDisplayName}',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Medical card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryWarning.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_hospital_rounded, color: AppColors.primaryWarning, size: 16),
                            SizedBox(width: 8),
                            Text('Emergency Medical Data',
                                style: TextStyle(color: AppColors.primaryWarning, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _medRow(Icons.bloodtype, 'Blood Type', widget.incident.bloodType ?? 'Unknown'),
                        const SizedBox(height: 8),
                        _medRow(Icons.medical_information, 'Allergies', widget.incident.allergies ?? 'None noted'),
                        const SizedBox(height: 8),
                        _medRow(Icons.location_on, 'Location', 'Within your response radius'),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Deny button
                TextButton.icon(
                  onPressed: _deny,
                  icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                  label: const Text('DENY', style: TextStyle(color: Colors.white38, letterSpacing: 2, fontSize: 12)),
                ),
                const SizedBox(height: 12),

                // Swipe-to-accept track
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Text('Slide to Accept →',
                          style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Track background
                          Container(
                            width: trackWidth,
                            height: 64,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primaryDanger.withValues(alpha: 0.4)),
                              borderRadius: BorderRadius.circular(32),
                              color: AppColors.primaryDanger.withValues(alpha: 0.1),
                            ),
                            child: const Center(
                              child: Text('ACCEPT',
                                  style: TextStyle(color: Colors.white24, letterSpacing: 4, fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          // Progress fill
                          Container(
                            width: (_dragX + handleSize).clamp(handleSize, trackWidth),
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryDanger.withValues(alpha: (_dragX / maxDrag).clamp(0.0, 1.0) * 0.6),
                                  AppColors.primaryDanger.withValues(alpha: (_dragX / maxDrag).clamp(0.0, 1.0) * 0.2),
                                ],
                              ),
                            ),
                          ),
                          // Draggable handle
                          Positioned(
                            left: _dragX.clamp(0.0, maxDrag),
                            child: GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  _dragX = (_dragX + details.delta.dx).clamp(0.0, maxDrag);
                                });
                                if (_dragX >= maxDrag * 0.85) unawaited(_accept());
                              },
                              onHorizontalDragEnd: (_) {
                                if (!_accepted) setState(() => _dragX = 0.0);
                              },
                              child: Container(
                                width: handleSize,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDanger,
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryDanger.withValues(alpha: 0.7),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _medRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}
