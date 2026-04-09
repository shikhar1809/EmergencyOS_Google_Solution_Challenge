import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Windows-style tray strip: language, connectivity, mic, volume, uptime, clock.
///
/// When [dockTray] is true, renders only the compact tray row (no full-width bar
/// chrome) for placement on the right inside the ops taskbar dock.
class OpsDashboardStatusBar extends StatefulWidget {
  const OpsDashboardStatusBar({
    super.key,
    required this.sessionStartedAt,
    this.dockTray = false,
  });

  final DateTime sessionStartedAt;
  final bool dockTray;

  @override
  State<OpsDashboardStatusBar> createState() => _OpsDashboardStatusBarState();
}

class _OpsDashboardStatusBarState extends State<OpsDashboardStatusBar> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  List<ConnectivityResult> _connectivity = const [ConnectivityResult.none];
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshConnectivity());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick++;
      if (mounted) {
        setState(() => _now = DateTime.now());
        if (_tick % 5 == 0) unawaited(_refreshConnectivity());
      }
    });
  }

  Future<void> _refreshConnectivity() async {
    try {
      final r = await Connectivity().checkConnectivity();
      if (mounted) setState(() => _connectivity = r);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatUptime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  IconData _networkIcon() {
    if (_connectivity.contains(ConnectivityResult.none)) {
      return Icons.wifi_off_rounded;
    }
    if (_connectivity.contains(ConnectivityResult.wifi)) {
      return Icons.wifi_rounded;
    }
    if (_connectivity.contains(ConnectivityResult.ethernet)) {
      return Icons.lan_rounded;
    }
    if (_connectivity.contains(ConnectivityResult.mobile)) {
      return Icons.signal_cellular_alt_rounded;
    }
    return Icons.wifi_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final locale = View.of(context).platformDispatcher.locale;
    final lang = locale.languageCode.toUpperCase();
    final region = (locale.countryCode ?? '').toUpperCase();
    final uptime = _now.difference(widget.sessionStartedAt);

    final tray = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              lang,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            Text(
              region.isEmpty ? '—' : region,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Icon(_networkIcon(), color: Colors.white70, size: 18),
        const SizedBox(width: 12),
        const Icon(Icons.mic_rounded, color: Colors.white70, size: 18),
        const SizedBox(width: 12),
        const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 18),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('HH:mm').format(_now),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              DateFormat('dd-MM-yyyy').format(_now),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                height: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Text(
          'Uptime ${_formatUptime(uptime)}',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    if (widget.dockTray) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: tray,
      );
    }

    return Material(
      color: const Color(0xFF1A1A1A),
      child: Container(
        height: 36,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [tray],
        ),
      ),
    );
  }
}
