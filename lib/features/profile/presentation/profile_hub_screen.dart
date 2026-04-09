import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/web_auth_redirect_bridge.dart';
import '../../../services/incident_service.dart';
import 'package:go_router/go_router.dart';

class ProfileHubScreen extends ConsumerStatefulWidget {
  const ProfileHubScreen({super.key, this.isDrillShell = false});

  final bool isDrillShell;

  @override
  ConsumerState<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends ConsumerState<ProfileHubScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'Anonymous';
    final email = user?.email;
    final phone = user?.phoneNumber;
    final photoUrl = user?.photoURL;
    final identifier = email ?? phone ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.profileTitle),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryDanger),
            onPressed: () async {
              if (!widget.isDrillShell &&
                  await IncidentService.mustStaySignedInForEmergencyFlow()) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Finish or exit your active SOS or response mission before signing out.',
                      ),
                      backgroundColor: AppColors.primaryDanger,
                    ),
                  );
                }
                return;
              }
              try {
                WebAuthRedirectBridge.clearPending();
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (widget.isDrillShell) ...[
            Material(
              color: Colors.cyan.shade900.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.school_rounded, color: Colors.cyanAccent.shade200, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.drillProfileBanner,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildImpactCard(),
          const SizedBox(height: 16),
          _buildProfileCard(displayName, identifier, photoUrl),
          const SizedBox(height: 20),
          _buildNavItem(
            context,
            icon: Icons.settings_rounded,
            title: 'General settings',
            subtitle: 'Language and display preferences',
            color: Colors.blueAccent,
            onTap: () => context.push(_prefixed('/profile/preferences')),
          ),
          const SizedBox(height: 12),
          _buildNavItem(
            context,
            icon: Icons.emergency_rounded,
            title: 'Emergency settings',
            subtitle: 'SOS PIN, Lifeline voice, dispatch bridge',
            color: AppColors.primaryDanger,
            onTap: () => context.push(_prefixed('/profile/emergency')),
          ),
          const SizedBox(height: 12),
          _buildNavItem(
            context,
            icon: Icons.medical_services_rounded,
            title: 'Medical details',
            subtitle: 'Blood type, allergies, emergency contacts',
            color: Colors.redAccent,
            onTap: () => context.push(_prefixed('/profile/medical')),
          ),
          const SizedBox(height: 12),
          _buildNavItem(
            context,
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy policy & terms of use',
            subtitle: 'How we handle your data and platform rules',
            color: Colors.amber,
            onTap: () => context.push(_prefixed('/profile/privacy')),
          ),
          const SizedBox(height: 12),
          _buildNavItem(
            context,
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'FAQs, guides, contact',
            color: Colors.purpleAccent,
            onTap: () => context.push(_prefixed('/profile/help')),
          ),
        ],
      ),
    );
  }

  String _prefixed(String path) {
    if (!widget.isDrillShell) return path;
    if (path.startsWith('/profile/')) {
      return '/drill/profile/${path.substring('/profile/'.length)}';
    }
    return path;
  }

  Widget _buildImpactCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final raw = data?['livesImpactEstimate'];
        final n = raw is num ? raw.toInt() : 0;
        final xp = (data?['volunteerXp'] as num?)?.toInt() ?? 0;
        final fmt = NumberFormat.decimalPattern();
        final displayLives = n > 0 ? n : (xp > 0 ? (1 + (xp / 500).floor()).clamp(1, 999) : 0);

        return Material(
          color: AppColors.primaryDanger.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(_prefixed('/profile/volunteer')),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDanger.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your life-saving impact',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayLives > 0
                              ? 'An estimated ${fmt.format(displayLives)} lives touched by your response activity.'
                              : 'Complete volunteer actions and assists to grow your impact score. Tap for volunteer details.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.35)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(String name, String identifier, String? photoUrl) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        final xp = (snap.data?.data()?['volunteerXp'] as num?)?.toInt() ?? 0;
        final xpFmt = NumberFormat.decimalPattern();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceHighlight,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, size: 32, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      identifier,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${xpFmt.format(xp)} XP',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
