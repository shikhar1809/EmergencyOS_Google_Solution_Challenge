import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WebVoiceGate extends StatelessWidget {
  final VoidCallback onVoiceGuided;
  final VoidCallback onSilenceMode;

  const WebVoiceGate({
    super.key,
    required this.onVoiceGuided,
    required this.onSilenceMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.82),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDanger.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryDanger.withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.sos_rounded,
                      size: 42,
                      color: AppColors.primaryDanger,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose your SOS mode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.97),
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your browser requires one tap to activate audio. Choose how you want to receive emergency guidance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _ModeButton(
                    icon: Icons.volume_up_rounded,
                    title: 'Voice-Guided Mode',
                    subtitle: 'Spoken safety prompts, questions & alerts',
                    accent: AppColors.primarySafe,
                    onTap: onVoiceGuided,
                  ),
                  const SizedBox(height: 14),
                  _ModeButton(
                    icon: Icons.volume_off_rounded,
                    title: 'Silence Mode',
                    subtitle: 'Visual-only \u2014 no audio will play',
                    accent: Colors.white,
                    onTap: onSilenceMode,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'You can change this anytime from the SOS screen',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = accent != Colors.white;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.25),
                        accent.withValues(alpha: 0.12),
                      ],
                    )
                  : null,
              color: isPrimary ? null : Colors.white.withValues(alpha: 0.065),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: isPrimary ? 0.55 : 0.18),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isPrimary ? 0.18 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: isPrimary ? 0.65 : 0.50,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: accent.withValues(alpha: isPrimary ? 0.7 : 0.35),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
