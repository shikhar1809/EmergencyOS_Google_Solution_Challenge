import 'package:flutter/material.dart';

import '../../../core/constants/india_ops_zones.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/ops_lifeline_analytics_chat.dart';
import '../domain/admin_panel_access.dart';

class MasterInsightsScreen extends StatefulWidget {
  const MasterInsightsScreen({super.key, required this.access});

  final AdminPanelAccess access;

  @override
  State<MasterInsightsScreen> createState() => _MasterInsightsScreenState();
}

class _InsightMsg {
  const _InsightMsg(this.isUser, this.text);
  final bool isUser;
  final String text;
}

class _MasterInsightsScreenState extends State<MasterInsightsScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_InsightMsg>[];
  bool _loading = false;
  IndiaOpsZone _zone = IndiaOpsZones.lucknow;

  @override
  void initState() {
    super.initState();
    _msgs.add(
      _InsightMsg(
        false,
        'Ask for **structured reports** on any ops zone (e.g. average EMS / first-response timing, '
        '7-day volume, hotspots). Pick a zone below, type a question, or tap a quick prompt.\n\n'
        'Data comes from the same live `sos_incidents` digest as Analytics — not a substitute for 112.',
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Map<String, String>> _historyBeforeLatest() {
    final hist = <Map<String, String>>[];
    for (var i = 0; i < _msgs.length - 1; i++) {
      final m = _msgs[i];
      hist.add({'role': m.isUser ? 'user' : 'model', 'text': m.text});
    }
    return hist;
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _msgs.add(_InsightMsg(true, t));
      _ctrl.clear();
    });
    _scrollToEnd();
    try {
      final reply = await OpsLifelineAnalyticsChat.send(
        message: t,
        zone: _zone,
        history: _historyBeforeLatest(),
        scenario:
            'Master Insights console — admin requests narrative reports and KPIs from live SOS analytics. '
            'Answer with clear sections, numbers from the digest when possible, and state uncertainty.',
        analyticsMode: true,
      );
      if (mounted) setState(() => _msgs.add(_InsightMsg(false, reply)));
    } catch (e) {
      if (mounted) {
        setState(() => _msgs.add(_InsightMsg(false, 'Could not generate report: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  Future<void> _quick(String prompt) async {
    await _send(prompt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.slate900,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.insights_rounded, color: AppColors.accentBlue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insights',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chat-style reports scoped to an ops zone — averages, EMS phases, trends, and risks. '
                        '(${widget.access.role.name} console)',
                        style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Zone:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<IndiaOpsZone>(
                    value: _zone,
                    dropdownColor: AppColors.slate800,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.slate800,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      for (final z in IndiaOpsZones.all)
                        DropdownMenuItem(value: z, child: Text(z.label)),
                    ],
                    onChanged: _loading
                        ? null
                        : (z) {
                            if (z == null) return;
                            setState(() => _zone = z);
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Avg EMS / response report'),
                  labelStyle: const TextStyle(fontSize: 11),
                  onPressed: _loading
                      ? null
                      : () => _quick(
                            'For ${_zone.label}: produce an **average EMS / first-response report** — '
                            'use dispatch phases, time-to-ack hints from the digest, active vs resolved mix, '
                            'and 7-day trend. Use bullet sections.',
                          ),
                ),
                ActionChip(
                  label: const Text('7-day volume & hotspots'),
                  labelStyle: const TextStyle(fontSize: 11),
                  onPressed: _loading
                      ? null
                      : () => _quick(
                            'For ${_zone.label}: **7-day incident volume** summary and **hex hotspot** interpretation '
                            '(where demand clusters, what to pre-stage).',
                          ),
                ),
                ActionChip(
                  label: const Text('Volunteer & triage stress'),
                  labelStyle: const TextStyle(fontSize: 11),
                  onPressed: _loading
                      ? null
                      : () => _quick(
                            'For ${_zone.label}: report on **volunteer attachment**, **triage severity**, '
                            'and operational stress indicators from the digest.',
                          ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _msgs.length,
                        itemBuilder: (_, i) {
                          final m = _msgs[i];
                          return Align(
                            alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: const BoxConstraints(maxWidth: 560),
                              decoration: BoxDecoration(
                                color: m.isUser
                                    ? AppColors.accentBlue.withValues(alpha: 0.22)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_loading) const LinearProgressIndicator(minHeight: 2),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              minLines: 1,
                              maxLines: 5,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText:
                                    'e.g. Lucknow ZONE — average EMS response & bottleneck summary…',
                                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onSubmitted: (_) => _send(_ctrl.text),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _loading ? null : () => _send(_ctrl.text),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              padding: const EdgeInsets.all(14),
                            ),
                            child: const Icon(Icons.send_rounded, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
