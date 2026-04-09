import 'package:flutter/material.dart';

import '../../services/privacy_consent_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Shown once before the first real SOS: location, optional profile medical fields, voice.
Future<bool> showEmergencyDataConsentIfNeeded(BuildContext context) async {
  final already = await PrivacyConsentService.hasAccepted();
  if (already) return true;
  if (!context.mounted) return false;

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l.emergencyConsentTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Text(
            l.emergencyConsentBody,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.45,
              fontSize: 14,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.consentNotNow,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDanger),
            child: Text(l.consentContinue),
          ),
        ],
      );
    },
  );

  if (ok == true) {
    await PrivacyConsentService.setAccepted(true);
    return true;
  }
  return false;
}
