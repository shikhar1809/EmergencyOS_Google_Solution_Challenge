import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/copilot_prefs.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/speech_web.dart'
    if (dart.library.io) '../../../../core/utils/speech_io.dart';
import '../../../../services/copilot_livekit_service.dart';
import '../../../../services/lifeline_training_chat_service.dart';
import '../../data/lifeline_curriculum_digest.dart';

/// LiveKit + Gemini training assistant with heartbeat states: idle → armed (red) → thinking (blue) → speaking (green) → idle.
class LifelineAgentHeartbeatOverlay extends ConsumerStatefulWidget {
  final int activeLevelIndex;
  final String activeLevelTitle;
  final EdgeInsets safePadding;

  const LifelineAgentHeartbeatOverlay({
    super.key,
    required this.activeLevelIndex,
    required this.activeLevelTitle,
    required this.safePadding,
  });

  @override
  ConsumerState<LifelineAgentHeartbeatOverlay> createState() =>
      _LifelineAgentHeartbeatOverlayState();
}

enum _AgentPulse {
  idle,
  armed,
  thinking,
  speaking,
}

class _LifelineAgentHeartbeatOverlayState
    extends ConsumerState<LifelineAgentHeartbeatOverlay>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _glitterController;

  _AgentPulse _phase = _AgentPulse.idle;
  final List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _glitterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant LifelineAgentHeartbeatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeLevelIndex != widget.activeLevelIndex &&
        _phase == _AgentPulse.armed) {
      unawaited(_republishCopilotContext());
    }
  }

  Future<void> _republishCopilotContext() async {
    final copilot = ref.read(copilotLivekitProvider);
    if (!copilot.isConnected) return;
    final walkthrough = await SharedPreferences.getInstance()
        .then((p) => p.getBool(CopilotPrefs.voiceWalkthroughEnabled) ?? false);
    final digest = LifelineCurriculumDigest.build();
    await copilot.publishPageContext(
      route: '/lifeline',
      title:
          'Lifeline L${widget.activeLevelIndex + 1}: ${widget.activeLevelTitle}',
      digest: digest,
      walkthrough: walkthrough,
    );
  }

  @override
  void dispose() {
    _glitterController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    cancelSpeechText();
    unawaited(ref.read(copilotLivekitProvider).disconnect());
    super.dispose();
  }

  Future<void> _onHeartTap() async {
    if (_phase == _AgentPulse.thinking) return;

    if (_phase == _AgentPulse.speaking) {
      cancelSpeechText();
      setState(() => _phase = _AgentPulse.idle);
      return;
    }

    if (_phase == _AgentPulse.armed) {
      cancelSpeechText();
      HapticFeedback.lightImpact();
      _focusNode.unfocus();
      setState(() => _phase = _AgentPulse.idle);
      _glitterController.stop();
      _glitterController.reset();
      await ref.read(copilotLivekitProvider).disconnect();
      return;
    }

    // idle → armed
    HapticFeedback.mediumImpact();
    setState(() => _phase = _AgentPulse.armed);
    _glitterController.repeat(reverse: true);

    final copilot = ref.read(copilotLivekitProvider);
    await copilot.connect(publishMic: false);
    if (!mounted) return;

    final walkthrough = await SharedPreferences.getInstance()
        .then((p) => p.getBool(CopilotPrefs.voiceWalkthroughEnabled) ?? false);
    final digest = LifelineCurriculumDigest.build();
    await copilot.publishPageContext(
      route: '/lifeline',
      title:
          'Lifeline L${widget.activeLevelIndex + 1}: ${widget.activeLevelTitle}',
      digest: digest,
      walkthrough: walkthrough,
    );
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _phase != _AgentPulse.armed) return;

    _focusNode.unfocus();
    _glitterController.stop();
    _glitterController.reset();

    final locale = ref.read(localeProvider);
    final bcp = lifelineTtsBcp47(locale.languageCode);

    setState(() => _phase = _AgentPulse.thinking);

    String reply;
    try {
      reply = await LifelineTrainingChatService.send(
        message: text,
        replyLocaleBcp47: bcp,
        history: List<Map<String, String>>.from(_history),
      );
    } catch (e) {
      reply = 'Could not reach the assistant. Check connection and try again.';
      debugPrint('[LifelineAgent] chat error: $e');
    }

    if (!mounted) return;

    _history.add({'role': 'user', 'text': text});
    _history.add({'role': 'model', 'text': reply});
    while (_history.length > 12) {
      _history.removeAt(0);
    }
    _textController.clear();

    setState(() => _phase = _AgentPulse.speaking);

    if (kIsWeb) {
      primeSpeechAudioContext();
    }

    speakText(
      reply,
      lang: bcp,
      onDone: () {
        if (!mounted) return;
        setState(() => _phase = _AgentPulse.idle);
      },
    );
  }

  Color _heartColor() {
    switch (_phase) {
      case _AgentPulse.idle:
        return AppColors.textSecondary.withValues(alpha: 0.45);
      case _AgentPulse.armed:
        return Colors.redAccent.shade200;
      case _AgentPulse.thinking:
        return Colors.lightBlueAccent.shade200;
      case _AgentPulse.speaking:
        return Colors.greenAccent.shade400;
    }
  }

  double _glitterScale() {
    if (_phase != _AgentPulse.armed) return 1.0;
    final t = _glitterController.value;
    return 1.0 + 0.06 * t;
  }

  List<BoxShadow> _heartShadows() {
    if (_phase == _AgentPulse.armed) {
      final pulse = 0.4 + 0.45 * _glitterController.value;
      return [
        BoxShadow(
          color: Colors.red.withValues(alpha: pulse),
          blurRadius: 18 + 14 * _glitterController.value,
          spreadRadius: 2 + 2 * _glitterController.value,
        ),
        BoxShadow(
          color: Colors.orangeAccent.withValues(alpha: 0.35 * pulse),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];
    }
    if (_phase == _AgentPulse.thinking) {
      return [
        BoxShadow(
          color: Colors.blue.withValues(alpha: 0.45),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ];
    }
    if (_phase == _AgentPulse.speaking) {
      return [
        BoxShadow(
          color: Colors.green.withValues(alpha: 0.5),
          blurRadius: 18,
          spreadRadius: 2,
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final bottom = widget.safePadding.bottom + 16;
    final right = 16.0;

    return Positioned(
      right: right,
      bottom: bottom,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_phase == _AgentPulse.armed)
              Container(
                width: MediaQuery.sizeOf(context).width * 0.55,
                constraints: const BoxConstraints(maxWidth: 320, minWidth: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.stroke),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: 2,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'First-aid question…',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded, size: 22),
                      color: AppColors.accentBlue,
                      tooltip: 'Send',
                    ),
                  ],
                ),
              ),
            Tooltip(
              message: _phase == _AgentPulse.idle
                  ? 'Tap to ask the Lifeline assistant'
                  : _phase == _AgentPulse.armed
                      ? 'Tap heart to cancel · type and send'
                      : _phase == _AgentPulse.thinking
                          ? 'Thinking…'
                          : 'Tap to stop speaking',
              child: GestureDetector(
                onTap: _onHeartTap,
                behavior: HitTestBehavior.opaque,
                child: Transform.scale(
                  scale: _glitterScale(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _phase == _AgentPulse.idle
                          ? AppColors.surfaceHighlight.withValues(alpha: 0.85)
                          : _heartColor().withValues(alpha: 0.2),
                      border: Border.all(
                        color: _heartColor(),
                        width: _phase == _AgentPulse.idle ? 1.5 : 2.2,
                      ),
                      boxShadow: _heartShadows(),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 28,
                      color: _heartColor(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
