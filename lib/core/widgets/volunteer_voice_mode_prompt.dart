import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../../services/voice_comms_service.dart';

/// Result of the volunteer voice mode prompt.
enum VolunteerVoiceMode {
  audio,
  silent,
}

/// Volunteer-only gate shown before opening an active consignment.
///
/// Lets the responder choose between full audio guidance and a silent,
/// visual-only experience. Mirrors the SOS Active web gate copy and styling.
class VolunteerVoiceModePrompt extends StatelessWidget {
  const VolunteerVoiceModePrompt({super.key});

  static Future<VolunteerVoiceMode?> show(BuildContext context) {
    return showDialog<VolunteerVoiceMode>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _VolunteerVoiceModeCard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _VolunteerVoiceModeCard();
  }
}

class _VolunteerVoiceModeCard extends StatelessWidget {
  const _VolunteerVoiceModeCard();

  Future<void> _select(
    BuildContext context,
    VolunteerVoiceMode mode,
  ) async {
    // Ensure any prior utterances are cleared before switching modes.
    VoiceCommsService.clearSpeakQueue();
    if (mode == VolunteerVoiceMode.audio) {
      VoiceCommsService.silenceMode = false;
      // Web / desktop: prime audio inside the same gesture.
      if (kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows))) {
        VoiceCommsService.primeForVoiceGuidance();
      }
    } else {
      VoiceCommsService.silenceMode = true;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                child: const Icon(Icons.volunteer_activism_rounded,
                    size: 40, color: AppColors.primaryDanger),
              ),
              const SizedBox(height: 18),
              Text(
                l.volunteerVoiceModeTitle,
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
                l.volunteerVoiceModeSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Audio mode button
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _select(context, VolunteerVoiceMode.audio),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primarySafe.withValues(alpha: 0.27),
                            AppColors.primarySafe.withValues(alpha: 0.14),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primarySafe.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primarySafe
                                    .withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.volume_up_rounded,
                                  color: AppColors.primarySafe, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.volunteerVoiceModeAudioTitle,
                                    style: const TextStyle(
                                      color: AppColors.primarySafe,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l.volunteerVoiceModeAudioSubtitle,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.70),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color:
                                  AppColors.primarySafe.withValues(alpha: 0.75),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Silent mode button
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _select(context, VolunteerVoiceMode.silent),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.065),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.volume_off_rounded,
                                  color:
                                      Colors.white.withValues(alpha: 0.80),
                                  size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.volunteerVoiceModeSilentTitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.90,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l.volunteerVoiceModeSilentSubtitle,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.55),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white.withValues(alpha: 0.40),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.volunteerVoiceModeFooter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

