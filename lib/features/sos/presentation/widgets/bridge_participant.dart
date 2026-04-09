enum BridgeRole {
  lifeline,
  emergencyDesk,
  emergencyContact,
  volunteerElite,
  acceptedVolunteer,
  victim,
  unknown,
}

class BridgeParticipant {
  final String identity;
  final BridgeRole role;
  final String displayName;
  final bool isSpeaking;

  const BridgeParticipant({
    required this.identity,
    required this.role,
    required this.displayName,
    this.isSpeaking = false,
  });

  static BridgeRole roleFromIdentity(String id) {
    if (id.startsWith('vol_elite_')) return BridgeRole.volunteerElite;
    if (id.startsWith('volunteer_')) return BridgeRole.acceptedVolunteer;
    if (id.startsWith('victim_')) return BridgeRole.victim;
    if (id.startsWith('ems_')) return BridgeRole.emergencyDesk;
    if (id.startsWith('contact_')) return BridgeRole.emergencyContact;
    if (id.startsWith('lifeline') || id.contains('agent'))
      return BridgeRole.lifeline;
    return BridgeRole.unknown;
  }

  static String emojiForRole(BridgeRole role) {
    switch (role) {
      case BridgeRole.lifeline:
        return '\U0001F916';
      case BridgeRole.emergencyDesk:
        return '\U0001F691';
      case BridgeRole.emergencyContact:
        return '\U0001F4DE';
      case BridgeRole.volunteerElite:
        return '\U0001F6E1\uFE0F';
      case BridgeRole.acceptedVolunteer:
        return '\U0001F91D';
      case BridgeRole.victim:
        return '\U0001F3A4';
      case BridgeRole.unknown:
        return '\U0001F464';
    }
  }

  static String nameForRole(BridgeRole role, String identity) {
    switch (role) {
      case BridgeRole.lifeline:
        return 'Assist';
      case BridgeRole.emergencyDesk:
        return 'Emergency Services';
      case BridgeRole.emergencyContact:
        return 'Emergency Contact';
      case BridgeRole.volunteerElite:
        return 'Elite Volunteer';
      case BridgeRole.acceptedVolunteer:
        return 'Volunteer';
      case BridgeRole.victim:
        return 'You';
      case BridgeRole.unknown:
        return identity.length > 16
            ? '${identity.substring(0, 16)}...'
            : identity;
    }
  }
}
