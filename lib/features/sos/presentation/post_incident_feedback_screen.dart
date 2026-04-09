import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/post_incident_feedback_service.dart';

/// Shown after the victim closes an SOS (optional — skip anytime).
class PostIncidentFeedbackScreen extends StatefulWidget {
  const PostIncidentFeedbackScreen({
    super.key,
    required this.incidentId,
    this.closureHint,
  });

  final String incidentId;
  final String? closureHint;

  @override
  State<PostIncidentFeedbackScreen> createState() => _PostIncidentFeedbackScreenState();
}

class _PostIncidentFeedbackScreenState extends State<PostIncidentFeedbackScreen> {
  bool? _helpful;
  int _rating = 0;
  String? _outcomeCategory;
  String? _resolvedByRole;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_helpful == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap “yes” or “no” first, or skip.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await PostIncidentFeedbackService.submit(
        incidentId: widget.incidentId,
        helpful: _helpful!,
        rating: _rating > 0 ? _rating : null,
        comment: _comment.text,
        closureHint: widget.closureHint,
        outcomeCategory: _outcomeCategory,
        resolvedByRole: _resolvedByRole,
      );
      if (!context.mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send feedback. $e')),
      );
    } finally {
      if (context.mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        backgroundColor: AppColors.slate800,
        title: const Text('Quick feedback'),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => context.go('/dashboard'),
            child: const Text('Skip', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Your answers are anonymous and only used to improve response quality. '
            'You can skip — no pressure.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 28),
          const Text(
            'Was the help you received useful?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: _busy ? null : () => setState(() => _helpful = true),
                style: FilledButton.styleFrom(
                  backgroundColor: _helpful == true ? AppColors.primarySafe : AppColors.slate700,
                ),
                child: const Text('Yes'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _busy ? null : () => setState(() => _helpful = false),
                style: FilledButton.styleFrom(
                  backgroundColor: _helpful == false ? AppColors.primaryDanger : AppColors.slate700,
                ),
                child: const Text('No'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Who helped resolve this incident?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'ambulance', 'volunteer', 'self', 'other'
            ].map((role) {
              final selected = _resolvedByRole == role;
              return FilterChip(
                label: Text(role.toUpperCase()),
                selected: selected,
                onSelected: _busy ? null : (v) => setState(() => _resolvedByRole = v ? role : null),
                backgroundColor: AppColors.slate800,
                selectedColor: AppColors.primarySafe,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'Overall Outcome',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'val': 'resolved', 'lbl': 'Resolved Successfully'},
              {'val': 'false_alarm', 'lbl': 'False Alarm'},
              {'val': 'unresolved', 'lbl': 'Not Resolved'}
            ].map((cat) {
              final selected = _outcomeCategory == cat['val'];
              return FilterChip(
                label: Text(cat['lbl']!),
                selected: selected,
                onSelected: _busy ? null : (v) => setState(() => _outcomeCategory = v ? cat['val']! : null),
                backgroundColor: AppColors.slate800,
                selectedColor: AppColors.primarySafe,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'Optional: overall rating',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final n = i + 1;
              return IconButton(
                onPressed: _busy ? null : () => setState(() => _rating = n),
                icon: Icon(
                  n <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: n <= _rating ? Colors.amber : Colors.white38,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 3,
            enabled: !_busy,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Optional comment',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: AppColors.slate800,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('Send (anonymous)'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
