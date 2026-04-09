import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// One row from [getOpsSystemHealth] (master console).
@immutable
class OpsServiceHealth {
  const OpsServiceHealth({
    required this.ok,
    required this.label,
    required this.detail,
  });

  final bool ok;
  final String label;
  final String detail;

  factory OpsServiceHealth.fromJson(Map<String, dynamic> j) {
    return OpsServiceHealth(
      ok: j['ok'] == true,
      label: (j['label'] ?? '').toString(),
      detail: (j['detail'] ?? '').toString(),
    );
  }
}

/// Aggregated backend status for GCP/Firebase, LiveKit, Twilio.
@immutable
class OpsSystemHealthReport {
  const OpsSystemHealthReport({
    required this.ok,
    required this.summary,
    required this.gcp,
    required this.livekit,
    required this.sms,
    required this.checkedAtMs,
  });

  final bool ok;
  final String summary;
  final OpsServiceHealth gcp;
  final OpsServiceHealth livekit;
  final OpsServiceHealth sms;
  final int checkedAtMs;

  factory OpsSystemHealthReport.fromResponse(Map<String, dynamic> raw) {
    if (raw.containsKey('livekitUrl') || raw.containsKey('activeRooms')) {
      final rooms = raw['activeRooms'];
      final n = rooms is num ? rooms.toInt() : int.tryParse('$rooms') ?? 0;
      final urlOk = '${raw['livekitUrl'] ?? ''}'.toLowerCase() == 'ok';
      return OpsSystemHealthReport(
        ok: urlOk,
        summary: 'Legacy getOpsSystemHealth response',
        gcp: const OpsServiceHealth(ok: true, label: 'GCP / Firestore', detail: 'Not reported by legacy callable'),
        livekit: OpsServiceHealth(
          ok: urlOk,
          label: 'LiveKit',
          detail: urlOk ? '$n active room(s) reported' : 'LiveKit URL missing in legacy response',
        ),
        sms: const OpsServiceHealth(ok: false, label: 'SMS (Twilio)', detail: 'Not reported by legacy callable'),
        checkedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    }

    final services = raw['services'];
    Map<String, dynamic> svc(String key) {
      if (services is! Map) return const {};
      final m = services[key];
      return m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map);
    }

    return OpsSystemHealthReport(
      ok: raw['ok'] == true,
      summary: (raw['summary'] ?? '').toString(),
      gcp: OpsServiceHealth.fromJson(svc('gcp')),
      livekit: OpsServiceHealth.fromJson(svc('livekit')),
      sms: OpsServiceHealth.fromJson(svc('sms')),
      checkedAtMs: (raw['checkedAt'] is num) ? (raw['checkedAt'] as num).toInt() : 0,
    );
  }
}

abstract final class OpsSystemHealthService {
  static Future<OpsSystemHealthReport> fetch() async {
    final callable = FirebaseFunctions.instance.httpsCallable('getOpsSystemHealth');
    final res = await callable.call();
    final data = res.data;
    if (data is! Map) {
      throw StateError('getOpsSystemHealth: unexpected response');
    }
    return OpsSystemHealthReport.fromResponse(Map<String, dynamic>.from(data));
  }
}

/// Hospital console: redacted integration probe (Firestore + LiveKit only, no SMS internals).
@immutable
class OpsDataPlaneHealthReport {
  const OpsDataPlaneHealthReport({
    required this.ok,
    required this.summary,
    required this.firestore,
    required this.livekit,
    required this.checkedAtMs,
  });

  final bool ok;
  final String summary;
  final OpsServiceHealth firestore;
  final OpsServiceHealth livekit;
  final int checkedAtMs;

  factory OpsDataPlaneHealthReport.fromResponse(Map<String, dynamic> raw) {
    final services = raw['services'];
    Map<String, dynamic> svc(String key) {
      if (services is! Map) return const {};
      final m = services[key];
      return m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map);
    }

    return OpsDataPlaneHealthReport(
      ok: raw['ok'] == true,
      summary: (raw['summary'] ?? '').toString(),
      firestore: OpsServiceHealth.fromJson(svc('firestore')),
      livekit: OpsServiceHealth.fromJson(svc('livekit')),
      checkedAtMs: (raw['checkedAt'] is num) ? (raw['checkedAt'] as num).toInt() : 0,
    );
  }
}

abstract final class OpsDataPlaneHealthService {
  static Future<OpsDataPlaneHealthReport> fetch() async {
    final callable = FirebaseFunctions.instance.httpsCallable('getOpsDataPlaneHealth');
    final res = await callable.call();
    final data = res.data;
    if (data is! Map) {
      throw StateError('getOpsDataPlaneHealth: unexpected response');
    }
    return OpsDataPlaneHealthReport.fromResponse(Map<String, dynamic>.from(data));
  }
}
