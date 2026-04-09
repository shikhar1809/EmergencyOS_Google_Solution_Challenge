import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../domain/admin_panel_access.dart';

class ObservatoryControlsTab extends StatefulWidget {
  const ObservatoryControlsTab({
    super.key,
    required this.accent,
    required this.access,
  });

  final Color accent;
  final AdminPanelAccess access;

  @override
  State<ObservatoryControlsTab> createState() => _ObservatoryControlsTabState();
}

class _ObservatoryControlsTabState extends State<ObservatoryControlsTab> {
  bool _applying = false;

  Future<void> _runAction(
    Future<void> Function() action,
    String successMsg,
  ) async {
    setState(() => _applying = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMsg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required Future<void> Function() action,
    required String confirmText,
    required String successMsg,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Type "$confirmText" to confirm',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (dialogCtx) {
                final ctrl = TextEditingController();
                return TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: confirmText,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _runAction(action, successMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    final isMaster = widget.access.role == AdminConsoleRole.master;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(
                  accent: a,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Controls',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMaster
                            ? 'Full system administration controls for the Lucknow ops zone.'
                            : 'Facility-scoped administrative controls.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  accent: a,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Management',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _applying
                                ? null
                                : () => _confirmAction(
                                    title: 'Refresh Cache',
                                    message:
                                        'Clear cached data and force a fresh pull from Firestore.',
                                    action: () async {
                                      await FirebaseFirestore.instance
                                          .clearPersistence();
                                    },
                                    confirmText: 'REFRESH',
                                    successMsg: 'Cache cleared successfully.',
                                  ),
                            icon: const Icon(Icons.sync_rounded, size: 18),
                            label: const Text('Refresh Cache'),
                            style: FilledButton.styleFrom(
                              backgroundColor: a.withValues(alpha: 0.7),
                            ),
                          ),
                          if (isMaster)
                            FilledButton.icon(
                              onPressed: _applying
                                  ? null
                                  : () => _confirmAction(
                                      title: 'Reset Leaderboard',
                                      message:
                                          'This will clear all leaderboard entries. This action cannot be undone.',
                                      action: () async {
                                        final snap = await FirebaseFirestore
                                            .instance
                                            .collection('leaderboard')
                                            .get();
                                        final batch = FirebaseFirestore.instance
                                            .batch();
                                        for (final doc in snap.docs) {
                                          batch.delete(doc.reference);
                                        }
                                        await batch.commit();
                                      },
                                      confirmText: 'RESET LEADERBOARD',
                                      successMsg: 'Leaderboard cleared.',
                                    ),
                              icon: const Icon(
                                Icons.leaderboard_rounded,
                                size: 18,
                              ),
                              label: const Text('Reset Leaderboard'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.shade900,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  accent: a,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Health',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _controlRow(
                        label: 'Firestore Connectivity',
                        description: 'Test database connection',
                        icon: Icons.storage_rounded,
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('_health_check')
                              .limit(1)
                              .get();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Firestore connection OK'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _controlRow(
                        label: 'Auth Status',
                        description: 'Check current auth state',
                        icon: Icons.verified_user_rounded,
                        onTap: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  user != null
                                      ? 'Signed in as ${user.email ?? user.uid}'
                                      : 'No user signed in',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (isMaster) ...[
                  const SizedBox(height: 14),
                  _card(
                    accent: a,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danger Zone',
                          style: TextStyle(
                            color: Colors.redAccent.shade200,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'These actions are irreversible. Proceed with extreme caution.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _applying
                                  ? null
                                  : () => _confirmAction(
                                      title: 'Clear Feedback',
                                      message:
                                          'Delete all incident feedback entries.',
                                      action: () async {
                                        final snap = await FirebaseFirestore
                                            .instance
                                            .collection('incident_feedback')
                                            .get();
                                        final batch = FirebaseFirestore.instance
                                            .batch();
                                        for (final doc in snap.docs) {
                                          batch.delete(doc.reference);
                                        }
                                        await batch.commit();
                                      },
                                      confirmText: 'CLEAR FEEDBACK',
                                      successMsg: 'Feedback cleared.',
                                    ),
                              icon: const Icon(
                                Icons.feedback_outlined,
                                size: 18,
                              ),
                              label: const Text('Clear Feedback'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _applying
                                  ? null
                                  : () => _confirmAction(
                                      title: 'Clear Green Zone Requests',
                                      message:
                                          'Delete all green zone requests.',
                                      action: () async {
                                        final snap = await FirebaseFirestore
                                            .instance
                                            .collection('green_zone_requests')
                                            .get();
                                        final batch = FirebaseFirestore.instance
                                            .batch();
                                        for (final doc in snap.docs) {
                                          batch.delete(doc.reference);
                                        }
                                        await batch.commit();
                                      },
                                      confirmText: 'CLEAR GREEN ZONE',
                                      successMsg:
                                          'Green zone requests cleared.',
                                    ),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: const Text('Clear Green Zone'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, required Color accent}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _controlRow({
    required String label,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: widget.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
