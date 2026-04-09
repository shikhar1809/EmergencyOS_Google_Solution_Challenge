import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LiveUpdatesCard extends StatelessWidget {
  final String incidentId;
  final bool isDrillMode;
  final List<Widget> drillTimelineEntries;
  final List<Widget> liveUpdateRows;

  const LiveUpdatesCard({
    super.key,
    required this.incidentId,
    required this.isDrillMode,
    required this.drillTimelineEntries,
    required this.liveUpdateRows,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.update_rounded,
                  color: AppColors.primaryInfo,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE UPDATES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySafe,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: TextStyle(
                    color: AppColors.primarySafe.withValues(alpha: 0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Dispatch, volunteers & device',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...liveUpdateRows,
            const Divider(height: 14, color: Colors.white12),
            Text(
              'Activity log',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            _ActivityLog(incidentId: incidentId),
          ],
        ),
      ),
    );
  }
}

class _ActivityLog extends StatelessWidget {
  final String incidentId;
  const _ActivityLog({required this.incidentId});

  @override
  Widget build(BuildContext context) {
    if (incidentId.isEmpty) {
      return const Text(
        '\u2014',
        style: TextStyle(color: Colors.white38, fontSize: 11),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sos_incidents')
          .doc(incidentId)
          .collection('victim_activity')
          .limit(24)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Loading\u2026',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          );
        }
        if (snap.hasError) {
          return Text(
            'Log unavailable',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Text(
            'Triage updates appear here.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.32),
              fontSize: 9,
              height: 1.3,
            ),
          );
        }
        int tsOf(QueryDocumentSnapshot<Map<String, dynamic>> d) {
          final c = d.data()['createdAt'];
          if (c is Timestamp) return c.millisecondsSinceEpoch;
          return 0;
        }

        final sorted = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          docs,
        )..sort((a, b) => tsOf(b).compareTo(tsOf(a)));
        final show = sorted.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: show.map((d) {
            final text = (d.data()['text'] as String?)?.trim() ?? '';
            final c = d.data()['createdAt'];
            String timeStr = '';
            if (c is Timestamp) {
              final t = c.toDate();
              timeStr =
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
            }
            if (text.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (timeStr.isNotEmpty)
                    SizedBox(
                      width: 34,
                      child: Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.32),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 9.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
