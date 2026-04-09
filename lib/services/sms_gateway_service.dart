import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SmsGatewayService
//
// Replaces P2PBroadcastService. Provides offline SOS dispatch when there is
// no data connection but cell signal is still available.
//
// Protocol: Open GeoSMS (used by Ushahidi, Sahana, OCHA tools)
//   Line 1: https://emergencyos.app/sos?x=LAT&y=LNG&type=TYPE&GeoSMS
//   Line 2: Human-readable summary (victim count, free text)
//   Line 3: Responder instructions (Reply Y/N)
//
// Any smartphone can tap the URL and map the location even without the app.
// Your backend Cloud Function (`parseSmsGateway`) ingests the payload via
// webhook and creates a Firestore incident, triggering normal FCM dispatch.
// ─────────────────────────────────────────────────────────────────────────────

/// Parsed payload from an inbound GeoSMS message.
class SmsIncidentPayload {
  final double latitude;
  final double longitude;
  final String type;
  final int victimCount;
  final String freeText;
  final String senderNumber;
  final String? incidentId;
  final String? channelText;

  const SmsIncidentPayload({
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.victimCount,
    required this.freeText,
    required this.senderNumber,
    this.incidentId,
    this.channelText,
  });
}

/// EmergencyOS: SmsGatewayService in lib/services/sms_gateway_service.dart.
class SmsGatewayService {
  // ── Build ──────────────────────────────────────────────────────────────────

  /// Builds a GeoSMS-formatted message body ready to send via SMS.
  ///
  /// [lat] / [lng]  — device GPS coordinates
  /// [type]         — incident type code e.g. 'CRASH', 'CARDIAC'
  /// [victimCount]  — number of victims (used by dispatcher for resource allocation)
  /// [freeText]     — optional plain-text detail (max ~80 chars recommended)
  static String buildGeoSms({
    required double lat,
    required double lng,
    required String type,
    required int victimCount,
    String freeText = '',
    String? incidentId,
    String? channelText,
  }) {
    // Encode to 6 decimal places (~11 cm accuracy — more than sufficient)
    final latStr = lat.toStringAsFixed(6);
    final lngStr = lng.toStringAsFixed(6);
    final safeType = Uri.encodeComponent(type.toUpperCase().replaceAll(' ', '_'));

    final geoUrl =
        '${AppConstants.geoSmsBaseUrl}?x=$latStr&y=$lngStr&type=$safeType'
        '${incidentId != null && incidentId.trim().isNotEmpty ? '&incidentId=${Uri.encodeComponent(incidentId.trim())}' : ''}'
        '${channelText != null && channelText.trim().isNotEmpty ? '&msg=${Uri.encodeComponent(channelText.trim())}' : ''}'
        '&GeoSMS';

    final summary = victimCount > 1
        ? 'Victims: $victimCount. $type.'
        : 'Victim: 1. $type.';

    final detail = freeText.trim().isNotEmpty ? ' ${freeText.trim()}' : '';
    final instructions =
        'EmergencyOS Alert — Reply Y to accept, N to decline.';

    return '$geoUrl\n$summary$detail\n$instructions';
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  /// Launches the native SMS app pre-populated with the GeoSMS payload.
  ///
  /// Recipients: gateway number is always included. Additional [extraNumbers]
  /// (e.g. local emergency contacts) are CC'd in the same SMS.
  ///
  /// Returns true if the SMS intent was successfully launched.
  static Future<bool> sendSmsViaIntent({
    required double lat,
    required double lng,
    required String type,
    required int victimCount,
    String freeText = '',
    List<String> extraNumbers = const [],
    String? incidentId,
    String? channelText,
  }) async {
    final body = buildGeoSms(
      lat: lat,
      lng: lng,
      type: type,
      victimCount: victimCount,
      freeText: freeText,
      incidentId: incidentId,
      channelText: channelText,
    );

    // Combine gateway + any extra responder numbers
    final allNumbers = [AppConstants.smsGatewayNumber, ...extraNumbers]
        .map((n) => n.replaceAll(RegExp(r'[^\d+]'), ''))
        .where((n) => n.isNotEmpty)
        .toSet()
        .join(';');

    final encoded = Uri.encodeComponent(body);
    final smsUri = Uri.parse('sms:$allNumbers?body=$encoded');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      debugPrint('[SmsGatewayService] Cannot launch SMS URI — scheme not supported on this platform.');
      return false;
    } catch (e) {
      debugPrint('[SmsGatewayService] SMS intent error: $e');
      return false;
    }
  }

  static const _prefSkipWebGeoSmsPrompt = 'geosms_web_prompt_skip_v1';

  /// Web: dialog with copyable GeoSMS and optional SMS URL; respects "don't show again".
  /// Native paths should use [tryOpenParallelGeoSmsRelay] instead.
  static Future<void> offerWebParallelGeoSmsIfNeeded(
    BuildContext context, {
    required double lat,
    required double lng,
    required String type,
    required String incidentId,
    int victimCount = 1,
    String freeText = '',
  }) async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final skipPrompt = prefs.getBool(_prefSkipWebGeoSmsPrompt) ?? false;
      final extras = await _smsRelayExtraNumbers();

      Future<void> launchSms() async {
        await sendSmsViaIntent(
          lat: lat,
          lng: lng,
          type: type,
          victimCount: victimCount,
          freeText: freeText,
          extraNumbers: extras,
          incidentId: incidentId,
        );
      }

      if (skipPrompt) {
        await launchSms();
        return;
      }

      final body = buildGeoSms(
        lat: lat,
        lng: lng,
        type: type,
        victimCount: victimCount,
        freeText: freeText,
        incidentId: incidentId,
      );

      if (!context.mounted) return;
      var dontShowAgain = false;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                title: const Text('Parallel SMS relay'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Copy this GeoSMS text and send it from a phone, or try Open SMS if this browser supports it. It links to your in-app SOS for responders.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        body,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                      CheckboxListTile(
                        value: dontShowAgain,
                        onChanged: (v) => setLocal(() => dontShowAgain = v ?? false),
                        title: const Text('Do not show again (open SMS automatically next time)'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: body));
                      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    child: const Text('Copy'),
                  ),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                  FilledButton(
                    onPressed: () async {
                      if (dontShowAgain) {
                        await prefs.setBool(_prefSkipWebGeoSmsPrompt, true);
                      }
                      Navigator.pop(ctx);
                      await launchSms();
                    },
                    child: const Text('Open SMS'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('[SmsGatewayService] Web GeoSMS offer: $e');
    }
  }

  /// Opens the native SMS composer with GeoSMS (gateway + profile contact when enabled).
  /// Runs in parallel with the in-app / Firestore SOS flow; does not replace it.
  /// No-op on web. Swallows errors so the main flow is never blocked.
  static Future<void> tryOpenParallelGeoSmsRelay({
    required double lat,
    required double lng,
    required String type,
    required String incidentId,
    int victimCount = 1,
    String freeText = '',
  }) async {
    if (kIsWeb) return;
    try {
      final extras = await _smsRelayExtraNumbers();
      await sendSmsViaIntent(
        lat: lat,
        lng: lng,
        type: type,
        victimCount: victimCount,
        freeText: freeText,
        extraNumbers: extras,
        incidentId: incidentId,
      );
    } catch (e) {
      debugPrint('[SmsGatewayService] Parallel GeoSMS relay: $e');
    }
  }

  static Future<List<String>> _smsRelayExtraNumbers() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return [];
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      final d = doc.data();
      final phone = (d?['contactPhone'] as String?)?.trim();
      final useSms = (d?['useEmergencyContactForSms'] as bool?) ?? false;
      if (useSms && phone != null && phone.isNotEmpty) return [phone];
    } catch (e) {
      debugPrint('[SmsGatewayService] Profile read for SMS CC: $e');
    }
    return [];
  }

  // ── Parse ──────────────────────────────────────────────────────────────────

  /// Parses an inbound raw GeoSMS string into a structured [SmsIncidentPayload].
  ///
  /// Validates that the message originated from EmergencyOS by checking for the
  /// GeoSMS base URL prefix. Returns null if the message is not a valid alert.
  static SmsIncidentPayload? parseGeoSms(String rawSms, {String senderNumber = ''}) {
    final lines = rawSms.trim().split('\n');
    if (lines.isEmpty) return null;

    final firstLine = lines[0].trim();
    if (!firstLine.startsWith(AppConstants.geoSmsBaseUrl)) return null;

    try {
      final uri = Uri.parse(firstLine.replaceAll('&GeoSMS', ''));
      final lat = double.tryParse(uri.queryParameters['x'] ?? '');
      final lng = double.tryParse(uri.queryParameters['y'] ?? '');
      final type = uri.queryParameters['type']?.replaceAll('_', ' ') ?? 'Unknown';
      // Optional incident/channel update fields
      final incidentId = uri.queryParameters['incidentId'];
      final channelText = uri.queryParameters['msg'];

      if (lat == null || lng == null) return null;

      // Parse victim count from line 2 e.g. "Victims: 3. Crash."
      int victimCount = 1;
      String freeText = '';
      if (lines.length > 1) {
        final match = RegExp(r'Victims?: (\d+)').firstMatch(lines[1]);
        if (match != null) victimCount = int.tryParse(match.group(1) ?? '1') ?? 1;
        // Anything after the type label is free text
        final parts = lines[1].split('. ');
        if (parts.length > 2) freeText = parts.sublist(2).join('. ');
      }

      return SmsIncidentPayload(
        latitude: lat,
        longitude: lng,
        type: type,
        victimCount: victimCount,
        freeText: freeText,
        senderNumber: senderNumber,
        incidentId: incidentId,
        channelText: channelText,
      );
    } catch (e) {
      debugPrint('[SmsGatewayService] Parse error: $e');
      return null;
    }
  }

  // ── Acknowledgement ────────────────────────────────────────────────────────

  /// Opens native SMS to send an acknowledgement back to an offline victim.
  ///
  /// Typically called by the dispatcher when an incident is accepted.
  /// [toNumber]  — the victim's phone number from the incident record
  /// [message]   — e.g. "EmergencyOS: Responder accepted. ETA ~7 min."
  static Future<void> sendAcknowledgement({
    required String toNumber,
    required String message,
  }) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$toNumber?body=$encoded');
    try {
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      debugPrint('[SmsGatewayService] Ack SMS error: $e');
    }
  }
}
