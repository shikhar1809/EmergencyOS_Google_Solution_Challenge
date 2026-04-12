import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/admin_panel_access.dart';

/// Lists narrative incident reports from `sos_incidents/{id}/incident_reports` (collection group).
class AdminReportsHubScreen extends StatelessWidget {
  const AdminReportsHubScreen({super.key, required this.access});

  final AdminPanelAccess access;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.MMMd().add_Hm();
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        backgroundColor: AppColors.slate800,
        title: const Text('Reports'),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collectionGroup('incident_reports')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${snap.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No incident reports yet. Generate one from the command center inspector.',
                  style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final incidentFromRef = d.reference.parent.parent?.id;
              final rawId = (data['incidentId'] as String?)?.trim() ?? '';
              final incidentId =
                  rawId.isNotEmpty ? rawId : (incidentFromRef ?? d.id);
              final narrative = (data['narrative'] as String?)?.trim() ?? '';
              final preview = narrative.isNotEmpty
                  ? narrative.split('\n').where((s) => s.trim().isNotEmpty).take(3).join('\n')
                  : '';
              final createdAt = data['createdAt'];
              DateTime? t;
              if (createdAt is Timestamp) {
                t = createdAt.toDate();
              }

              return Card(
                color: AppColors.slate800,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    incidentId,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      preview.isNotEmpty ? preview : '—',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35),
                    ),
                  ),
                  trailing: t != null
                      ? Text(
                          fmt.format(t.toLocal()),
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        )
                      : null,
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.slate800,
                        title: Text(
                          incidentId,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        content: SizedBox(
                          width: 520,
                          child: SingleChildScrollView(
                            child: SelectableText(
                              narrative.isNotEmpty ? narrative : '$data',
                              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
