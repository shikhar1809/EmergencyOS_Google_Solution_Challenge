import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/emergency_numbers.dart';

class SosCountdownOverlay extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const SosCountdownOverlay({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  ConsumerState<SosCountdownOverlay> createState() => _SosCountdownOverlayState();
}

class _SosCountdownOverlayState extends ConsumerState<SosCountdownOverlay> {
  int _secondsRemaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        widget.onConfirm();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final emergencyNumber = EmergencyNumbers.primaryNumberForLocale(locale);
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: AppColors.primaryDanger)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: const Duration(seconds: 1)),
              const SizedBox(height: 24),
              Text(
                'EMERGENCY\nSOS TRIGGERED',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primaryDanger,
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Notifying emergency services and\nnearby volunteers in:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'If this is life‑threatening, do not wait for the app.\nCall local emergency services now.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.25,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: emergencyNumber);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: Text('CALL $emergencyNumber'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryDanger, width: 4),
                ),
                child: Center(
                  child: Text(
                    _secondsRemaining.toString(),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  label: const Text('CANCEL (False Alarm)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: widget.onConfirm,
                  icon: const Icon(Icons.send),
                  label: const Text('SEND NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDanger,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }
}
