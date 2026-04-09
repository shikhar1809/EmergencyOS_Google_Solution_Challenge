import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/sms_gateway_service.dart';
import '../../../services/incident_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SmsSosScreen
//
// Shown when no data connection is available. Guides the user through
// sending an SOS via native SMS using the Open GeoSMS protocol.
//
// Flow:
//   1. App detects offline → navigates here instead of normal SOS flow.
//   2. User selects incident type + victim count + optional free text.
//   3. Taps "SEND SOS VIA SMS" → native SMS app opens, pre-populated.
//   4. Gateway receives SMS → parses payload → creates Firestore incident.
//   5. User receives acknowledgement SMS when a responder accepts.
// ─────────────────────────────────────────────────────────────────────────────

class SmsSosScreen extends StatefulWidget {
  const SmsSosScreen({super.key});

  @override
  State<SmsSosScreen> createState() => _SmsSosScreenState();
}

class _SmsSosScreenState extends State<SmsSosScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  String _selectedType = 'Medical';
  int _victimCount = 1;
  String _freeText = '';
  bool _isSending = false;
  bool _smsSent = false;
  String? _gpsError;
  Position? _position;

  static const _typeOptions = [
    {'label': 'Medical',   'icon': Icons.monitor_heart_rounded,       'code': 'MEDICAL'},
    {'label': 'Crash',     'icon': Icons.car_crash_rounded,            'code': 'CRASH'},
    {'label': 'Fire',      'icon': Icons.local_fire_department_rounded,'code': 'FIRE'},
    {'label': 'Violence',  'icon': Icons.warning_amber_rounded,        'code': 'VIOLENCE'},
    {'label': 'Disaster',  'icon': Icons.storm_rounded,                'code': 'DISASTER'},
  ];

  @override
  void initState() {
    super.initState();
    _acquireGps();
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _acquireGps() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      if (context.mounted) setState(() => _position = pos);
    } catch (e) {
      if (context.mounted) setState(() => _gpsError = 'GPS unavailable. SMS will be sent without coordinates.');
    }
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> _sendSmsSos() async {
    setState(() => _isSending = true);

    final lat = _position?.latitude ?? 0.0;
    final lng = _position?.longitude ?? 0.0;
    final code = (_typeOptions.firstWhere(
      (t) => t['label'] == _selectedType, orElse: () => _typeOptions[0])['code'] as String);

    // Also write a local Firestore document (will sync when connectivity restores)
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'guest';
      final name = user?.displayName ?? user?.email?.split('@').first ?? 'User';
      await IncidentService.createIncident(
        userId: userId,
        userDisplayName: name,
        location: LatLng(lat, lng),
        type: '$_selectedType (SMS-offline). Victims: $_victimCount. $_freeText',
      );
    } catch (_) {}

    final launched = await SmsGatewayService.sendSmsViaIntent(
      lat: lat,
      lng: lng,
      type: code,
      victimCount: _victimCount,
      freeText: _freeText,
    );

    if (!context.mounted) return;
    setState(() {
      _isSending = false;
      _smsSent = launched;
    });

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open SMS app. Please call 112 directly.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OFFLINE SOS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.orange.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Offline Banner ────────────────────────────────────────────
            _buildOfflineBanner(),
            const SizedBox(height: 24),

            if (_smsSent) ...[
              _buildSuccessCard(),
              const SizedBox(height: 24),
            ],

            // ── GPS Status ────────────────────────────────────────────────
            _buildGpsCard(),
            const SizedBox(height: 24),

            // ── Incident Type ─────────────────────────────────────────────
            _buildSectionLabel('EMERGENCY TYPE'),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // ── Victim Count ──────────────────────────────────────────────
            _buildSectionLabel('VICTIMS'),
            const SizedBox(height: 12),
            _buildVictimStepper(),
            const SizedBox(height: 24),

            // ── Free Text ─────────────────────────────────────────────────
            _buildSectionLabel('DETAILS (optional, max 80 chars)'),
            const SizedBox(height: 8),
            TextField(
              maxLength: 80,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                counterStyle: const TextStyle(color: Colors.white38),
                hintText: 'e.g. 2 injured, car vs bike, unconscious...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (v) => _freeText = v,
            ),
            const SizedBox(height: 8),

            // ── SMS Preview ───────────────────────────────────────────────
            _buildSmsPreview(),
            const SizedBox(height: 32),

            // ── Send Button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendSmsSos,
                icon: _isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _smsSent ? 'RESEND SOS SMS' : 'SEND SOS VIA SMS',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  disabledBackgroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: Colors.orangeAccent.withValues(alpha: 0.4),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No internet required — SMS uses cell signal only.\nRecipients can tap the location link without the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.6),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.6), width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NO DATA CONNECTION', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                SizedBox(height: 4),
                Text(
                  'Switching to SMS Emergency Relay. Your SOS will be sent to the EmergencyOS gateway and your emergency contacts via text message.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildGpsCard() {
    final hasGps = _position != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (hasGps ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (hasGps ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(hasGps ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
              color: hasGps ? Colors.greenAccent : Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasGps
                  ? 'GPS: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                  : (_gpsError ?? 'Acquiring GPS…'),
              style: TextStyle(
                color: hasGps ? Colors.greenAccent : Colors.orangeAccent,
                fontSize: 12, fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!hasGps && _gpsError == null)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent)),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _typeOptions.map((opt) {
        final isSelected = opt['label'] == _selectedType;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = opt['label'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.withValues(alpha: 0.2) : AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? Colors.orangeAccent : Colors.white12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt['icon'] as IconData, size: 16, color: isSelected ? Colors.orangeAccent : Colors.white38),
                const SizedBox(width: 8),
                Text(
                  opt['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVictimStepper() {
    return Row(
      children: [
        _stepperButton(Icons.remove_rounded, () {
          if (_victimCount > 1) setState(() => _victimCount--);
        }),
        const SizedBox(width: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Text(
            _victimCount.toString(),
            key: ValueKey(_victimCount),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 40),
          ),
        ),
        const SizedBox(width: 20),
        _stepperButton(Icons.add_rounded, () => setState(() => _victimCount++)),
        const SizedBox(width: 16),
        Text(
          _victimCount == 1 ? 'victim' : 'victims',
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSmsPreview() {
    final lat = _position?.latitude ?? 0.0;
    final lng = _position?.longitude ?? 0.0;
    final code = (_typeOptions.firstWhere(
      (t) => t['label'] == _selectedType, orElse: () => _typeOptions[0])['code'] as String);
    final preview = SmsGatewayService.buildGeoSms(
      lat: lat, lng: lng, type: code, victimCount: _victimCount, freeText: _freeText,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SMS PREVIEW', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(preview, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.6, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SMS LAUNCHED ✓', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 13)),
                SizedBox(height: 4),
                Text(
                  'Respond to your SOS via the SMS app. Keep this screen open. You may receive an acknowledgement SMS when a responder accepts.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
    );
  }
}
