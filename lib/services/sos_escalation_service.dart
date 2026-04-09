import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

/// Manages the 3-tier SOS escalation logic.
/// Tier 1 (T+0s):   Alert volunteers within 5 km.
/// Tier 2 (T+60s):  No response – expand radius to 15 km.
/// Tier 3 (T+120s): Still no response – auto-dial emergency services.
class SosEscalationService {
  Timer? _tier2Timer;
  Timer? _tier3Timer;

  /// [onTier2] is called at the 60-second mark.
  /// [onTier3] is called at the 120-second mark.
  void startEscalation({
    required void Function() onTier2,
    required void Function() onTier3,
  }) {
    _tier2Timer = Timer(const Duration(seconds: 60), () {
      onTier2();
      _tier3Timer = Timer(const Duration(seconds: 60), onTier3);
    });
  }

  /// Call this when a volunteer accepts, so timers are cancelled.
  void cancel() {
    _tier2Timer?.cancel();
    _tier3Timer?.cancel();
  }

  /// Dial emergency number; shows snackbar on web where tel: links won't fire.
  static Future<void> dialEmergency() async {
    final uri = Uri.parse('tel:112');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void dispose() => cancel();
}
