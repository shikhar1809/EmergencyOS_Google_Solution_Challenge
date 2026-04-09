import 'package:firebase_auth/firebase_auth.dart';

import 'leaderboard_service.dart';

/// Synthetic leaderboard + stats for the Home dashboard during drill mode.
class DrillDashboardFakes {
  DrillDashboardFakes._();

  static const int fakeActiveAlerts = 4;
  static const int fakeMyResponses = 27;

  static List<LeaderboardEntry> leaderboard() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'practice_self';
    final rows = <LeaderboardEntry>[
      const LeaderboardEntry(
        userId: 'lb_demo_1',
        displayName: 'Ananya Rao',
        responseCount: 112,
        isCurrentUser: false,
        onDutyMinutes: 8420,
        volunteerXp: 18940,
      ),
      const LeaderboardEntry(
        userId: 'lb_demo_2',
        displayName: 'Vikram Mehta',
        responseCount: 96,
        isCurrentUser: false,
        onDutyMinutes: 6100,
        volunteerXp: 16220,
      ),
      const LeaderboardEntry(
        userId: 'lb_demo_3',
        displayName: 'Drishti Kaur',
        responseCount: 88,
        isCurrentUser: false,
        onDutyMinutes: 5400,
        volunteerXp: 14850,
      ),
      LeaderboardEntry(
        userId: uid,
        displayName: 'You (practice)',
        responseCount: fakeMyResponses,
        isCurrentUser: true,
        onDutyMinutes: 2180,
        volunteerXp: 9260,
      ),
      const LeaderboardEntry(
        userId: 'lb_demo_4',
        displayName: 'Rahul Verma',
        responseCount: 71,
        isCurrentUser: false,
        onDutyMinutes: 4200,
        volunteerXp: 8940,
      ),
      const LeaderboardEntry(
        userId: 'lb_demo_5',
        displayName: 'Sneha Iyer',
        responseCount: 65,
        isCurrentUser: false,
        onDutyMinutes: 3900,
        volunteerXp: 8120,
      ),
      const LeaderboardEntry(
        userId: 'lb_demo_6',
        displayName: 'Arjun Nair',
        responseCount: 58,
        isCurrentUser: false,
        onDutyMinutes: 3100,
        volunteerXp: 7680,
      ),
      const LeaderboardEntry(
        userId: 'lb_demo_7',
        displayName: 'Kavya Menon',
        responseCount: 52,
        isCurrentUser: false,
        onDutyMinutes: 2800,
        volunteerXp: 7010,
      ),
      const LeaderboardEntry(
        userId: 'lb_demo_8',
        displayName: 'Imran Qureshi',
        responseCount: 47,
        isCurrentUser: false,
        onDutyMinutes: 2500,
        volunteerXp: 6340,
      ),
      const LeaderboardEntry(
        userId: 'lb_demo_9',
        displayName: 'Neha Bhatt',
        responseCount: 41,
        isCurrentUser: false,
        onDutyMinutes: 2200,
        volunteerXp: 5890,
      ),
      const LeaderboardEntry(
        userId: 'lb_demo_10',
        displayName: 'Unit 7 — Rapid',
        responseCount: 38,
        isCurrentUser: false,
        onDutyMinutes: 9900,
        volunteerXp: 5420,
      ),
    ];

    rows.sort((a, b) => b.score.compareTo(a.score));
    return rows
        .map(
          (e) => LeaderboardEntry(
            userId: e.userId,
            displayName: e.displayName,
            responseCount: e.responseCount,
            isCurrentUser: e.userId == uid,
            onDutyMinutes: e.onDutyMinutes,
            volunteerXp: e.volunteerXp,
          ),
        )
        .toList();
  }
}
