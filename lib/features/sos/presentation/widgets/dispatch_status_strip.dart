import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dispatch_chain_service.dart';

class DispatchStatusStrip extends StatefulWidget {
  final String incidentId;
  final void Function(String text)? onSpeakGuidance;

  const DispatchStatusStrip({
    super.key,
    required this.incidentId,
    this.onSpeakGuidance,
  });

  @override
  State<DispatchStatusStrip> createState() => _DispatchStatusStripState();
}

class _DispatchStatusStripState extends State<DispatchStatusStrip> {
  String? _lastSpokenPhase;
  String? _lastSpokenHospital;
  int? _lastSpokenTier;

  void _maybeSpeak(DispatchChainState state) {
    final speak = widget.onSpeakGuidance;
    if (speak == null) return;
    final status = state.status;
    final hospName = state.currentHospitalName;
    final tier = state.currentTier;

    if (status == 'pending_acceptance' && _lastSpokenHospital != hospName) {
      _lastSpokenHospital = hospName;
      if (_lastSpokenTier != tier) {
        _lastSpokenTier = tier;
        if (tier == 1) {
          speak('Alerting nearest hospital in your area. Trying $hospName.');
        } else {
          speak('No response. Escalating to tier $tier. Trying $hospName.');
        }
      } else {
        speak('No response from previous hospital. Trying $hospName.');
      }
    }
    if (status == 'accepted' && _lastSpokenPhase != 'accepted') {
      _lastSpokenPhase = 'accepted';
      speak(
        '$hospName has accepted your emergency. Ambulance coordination underway.',
      );
    }
    if (status == 'exhausted' && _lastSpokenPhase != 'exhausted') {
      _lastSpokenPhase = 'exhausted';
      speak('All hospitals notified. Please call 112 for emergency services.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DispatchChainState>(
      stream: DispatchChainService.watchForIncident(widget.incidentId),
      builder: (context, snap) {
        final state = snap.data;
        final assignment = state?.assignment;
        final status = state?.status ?? 'none';

        if (assignment == null || status == 'none') {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              'We are contacting nearby hospitals based on your location and emergency type.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          );
        }

        _maybeSpeak(state!);

        final hospName = state.currentHospitalName;
        final tierLabel = state.currentTierLabel;
        final countdown = state.countdownSecondsRemaining;
        final ambSt = (assignment.ambulanceDispatchStatus ?? '').trim();
        String title;
        String subtitle;
        Color? tierColor;

        if (ambSt == 'pending_operator') {
          title = 'Ambulance crew notified';
          subtitle =
              'A partner hospital accepted your case. Ambulance operators are being alerted.';
        } else if (ambSt == 'ambulance_en_route') {
          title = 'Ambulance confirmed';
          final unit = (assignment.assignedFleetCallSign ?? '').trim();
          subtitle = unit.isNotEmpty
              ? 'Unit $unit is en route to you. Stay where responders can reach you.'
              : 'An ambulance is en route to you. Stay where responders can reach you.';
        } else if (ambSt == 'no_operator') {
          title = 'Ambulance handoff delayed';
          subtitle =
              'A hospital accepted, but no ambulance crew confirmed in time. Dispatch is escalating -- if needed, call 112.';
        } else {
          switch (status) {
            case 'pending_acceptance':
              title = 'Trying: $hospName';
              subtitle = '$tierLabel \u00b7 Waiting for hospital response.';
              tierColor = state.currentTier == 1
                  ? Colors.redAccent
                  : state.currentTier == 2
                  ? Colors.amber
                  : Colors.blueGrey;
              break;
            case 'accepted':
              title = '$hospName accepted';
              subtitle = 'Ambulance dispatch is being coordinated.';
              tierColor = Colors.greenAccent;
              break;
            case 'exhausted':
              title = 'All hospitals notified';
              subtitle =
                  'No hospital accepted in time. Dispatch is escalating to emergency services.';
              tierColor = AppColors.primaryDanger;
              break;
            default:
              title = 'Hospital dispatch';
              subtitle = '$hospName \u00b7 $status';
              break;
          }
        }

        final countdownStr = countdown != null && countdown > 0
            ? '${(countdown ~/ 60).toString().padLeft(2, '0')}:${(countdown % 60).toString().padLeft(2, '0')}'
            : null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tierColor?.withValues(alpha: 0.5) ?? Colors.white10,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                status == 'accepted'
                    ? Icons.check_circle_rounded
                    : Icons.local_hospital_rounded,
                color: tierColor ?? Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: tierColor ?? Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (countdownStr != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (countdown != null && countdown <= 30)
                        ? AppColors.primaryDanger.withValues(alpha: 0.25)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    countdownStr,
                    style: TextStyle(
                      color: (countdown != null && countdown <= 30)
                          ? AppColors.primaryDanger
                          : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
