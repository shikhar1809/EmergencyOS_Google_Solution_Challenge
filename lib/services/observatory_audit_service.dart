import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Single row merged from `sos_incidents/{id}/audit_log` across several incidents.
@immutable
class MergedAuditRow {
  const MergedAuditRow({
    required this.incidentId,
    required this.at,
    required this.actorUid,
    required this.action,
    required this.fromStatus,
    required this.toStatus,
    required this.note,
  });

  final String incidentId;
  final DateTime at;
  final String actorUid;
  final String action;
  final String fromStatus;
  final String toStatus;
  final String note;

  static String _fmtTime(DateTime t) =>
      DateFormat.yMMMd().add_Hms().format(t.toLocal());

  /// CSV header compatible with ops desk export.
  static const csvHeader = 'incidentId,at,actorUid,action,fromStatus,toStatus,note';

  List<String> toCsvFields() => [
        incidentId,
        _fmtTime(at),
        actorUid,
        action,
        fromStatus,
        toStatus,
        note.replaceAll(',', ';'),
      ];
}

abstract final class ObservatoryAuditService {
  static final _db = FirebaseFirestore.instance;

  /// Parallel reads per incident; results merged newest-first, capped at [maxTotal].
  static Future<List<MergedAuditRow>> fetchMerged({
    required List<String> incidentIds,
    int perIncidentLimit = 24,
    int maxTotal = 280,
  }) async {
    final ids = incidentIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const [];

    final futures = ids.map((id) async {
      try {
        final snap = await _db
            .collection('sos_incidents')
            .doc(id)
            .collection('audit_log')
            .orderBy('at', descending: true)
            .limit(perIncidentLimit)
            .get();
        return snap.docs.map((d) => _row(id, d.data())).toList();
      } catch (e) {
        debugPrint('[ObservatoryAuditService] $id: $e');
        return <MergedAuditRow>[];
      }
    });

    final chunks = await Future.wait(futures);
    final flat = chunks.expand((e) => e).toList();
    flat.sort((a, b) => b.at.compareTo(a.at));
    if (flat.length <= maxTotal) return flat;
    return flat.sublist(0, maxTotal);
  }

  static MergedAuditRow _row(String incidentId, Map<String, dynamic> m) {
    final atRaw = m['at'];
    DateTime at;
    if (atRaw is Timestamp) {
      at = atRaw.toDate();
    } else {
      at = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return MergedAuditRow(
      incidentId: incidentId,
      at: at,
      actorUid: (m['actorUid'] ?? '').toString(),
      action: (m['action'] ?? '').toString(),
      fromStatus: (m['fromStatus'] ?? '').toString(),
      toStatus: (m['toStatus'] ?? '').toString(),
      note: (m['note'] ?? '').toString(),
    );
  }

  static String toCsv(List<MergedAuditRow> rows) {
    final buf = StringBuffer(MergedAuditRow.csvHeader);
    for (final r in rows) {
      buf.writeln();
      buf.write(r.toCsvFields().join(','));
    }
    return buf.toString();
  }
}
