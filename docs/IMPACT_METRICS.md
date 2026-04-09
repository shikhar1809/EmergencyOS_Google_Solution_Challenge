# Impact metrics framework

## In-app events (`analytics_events`)

Emitted by `UsageAnalyticsService` (see `lib/services/usage_analytics_service.dart`):

| Event | Meaning |
|-------|---------|
| `sos_initiated` | User began a live SOS path |
| `sos_completed` | SOS pipeline reached “active / dispatched” state |
| `time_to_first_guidance` | ms from SOS start to first guidance surface |
| `volunteer_accepted_latency` | ms from incident creation to first acceptance |
| `triage_camera_used` | Camera triage flow opened |
| `lifeline_level_completed` | Training level ID completed |
| `golden_hour_milestone_reached` | Golden hour minute mark fired |
| `drill_completed` | Drill mode finished |

## Dashboard KPIs

1. **Incidents handled** — count of closed / acknowledged incidents in window  
2. **Mean volunteer acceptance time** — from `volunteer_accepted_latency` or Firestore deltas  
3. **Training completion rate** — `lifeline_level_completed` / active users  
4. **Coverage** — hex zones with ≥ N on-duty volunteers  

## Reporting

- Refresh weekly during pilot; export CSV from BigQuery or Firestore exports if enabled.  
- Pair quantitative metrics with **PILOT_STUDY.md** qualitative themes.
