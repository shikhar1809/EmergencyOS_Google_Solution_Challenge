/// Default volunteer XP amounts (SOS + closures). Kept in one place for
/// [IncidentService] and [MasterXpTuningService] defaults.
abstract final class VolunteerXpRewards {
  static const int acceptIncident = 100;
  static const int onSceneChecklist = 200;
  static const int victimMarkedResolved = 500;
  static const int falseAlarmClosure = 180;
}
