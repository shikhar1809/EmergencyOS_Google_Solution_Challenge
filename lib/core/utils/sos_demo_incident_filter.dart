// Filters seeded / training SOS documents so leaderboards and maps use real incidents only.

bool isDemoSosFirestoreDoc(String docId, Map<String, dynamic> data) {
  if (docId.startsWith('seed_')) return true;
  if (docId.startsWith('demo_')) return true;
  final uid = data['userId']?.toString() ?? '';
  if (uid.startsWith('vol_')) return true;
  if (data['demo'] == true || data['training'] == true) return true;
  return false;
}

/// Training / seeded accounts — excluded from the live app leaderboard.
bool isDemoLeaderboardUserId(String uid) {
  final u = uid.trim();
  if (u.isEmpty) return true;
  if (u.startsWith('lb_demo_')) return true;
  if (u.startsWith('demo_')) return true;
  if (u == 'drill_demo') return true;
  if (u.startsWith('vol_demo_')) return true;
  return false;
}
