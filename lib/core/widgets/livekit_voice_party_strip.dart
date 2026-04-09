import 'package:flutter/material.dart';

/// One participant in a horizontal Discord-style voice strip.
class LivekitVoicePartyAvatar {
  const LivekitVoicePartyAvatar({
    required this.label,
    this.isSpeaking = false,
    this.isLocal = false,
  });

  final String label;
  final bool isSpeaking;
  final bool isLocal;

  String get initials {
    final t = label.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final s = parts[0];
      if (s.length >= 2) return s.substring(0, 2).toUpperCase();
      return s.toUpperCase();
    }
    final a = parts[0];
    final b = parts[1];
    if (a.isEmpty) return '?';
    if (b.isEmpty) return a.substring(0, 1).toUpperCase();
    return '${a[0]}${b[0]}'.toUpperCase();
  }
}

/// Horizontal row of voice participants with a green outline while speaking.
class LivekitVoicePartyStrip extends StatelessWidget {
  const LivekitVoicePartyStrip({
    super.key,
    required this.avatars,
    this.backgroundColor = const Color(0xFF161B22),
  });

  final List<LivekitVoicePartyAvatar> avatars;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < avatars.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                _PartyAvatarTile(avatar: avatars[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PartyAvatarTile extends StatelessWidget {
  const _PartyAvatarTile({required this.avatar});

  final LivekitVoicePartyAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final speaking = avatar.isSpeaking;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: speaking ? const Color(0xFF22C55E) : Colors.white24,
              width: speaking ? 2.5 : 1,
            ),
            boxShadow: speaking
                ? [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: avatar.isLocal ? const Color(0xFF134E4A) : const Color(0xFF1E293B),
            child: Text(
              avatar.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 72),
          child: Text(
            avatar.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: speaking ? Colors.white : Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}
