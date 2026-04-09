# Cloud Functions Architecture

## Modular Structure

The original `index.js` (3,588 lines) has been decomposed into the following modules:

| Module | Responsibility |
|--------|---------------|
| `src/utils.js` | Shared utilities: GeoHash, hex grid math, ops zones, helpers |
| `src/gemini_ai.js` | Gemini AI: triage image analysis, Lifeline chat, situation briefs, video/voice analysis |
| `src/hospital_chain.js` | Hospital dispatch: tiered escalation, GeoHash queries, acceptance/decline, scheduled escalation |
| `src/livekit_tokens.js` | LiveKit WebRTC: token generation, emergency bridge, copilot room, ops health |
| `src/sms_gateway.js` | SMS: Twilio webhook, emergency contact notifications, incident update SMS |
| `src/leaderboard.js` | Leaderboard: XP aggregation, volunteer stats |
| `src/fleet_assignments.js` | Fleet: ambulance dispatch, operator notifications, escalation |

## Migration Strategy

The original `index.js` remains the deployed entry point. The modular files in `src/` are:
1. **Reference implementations** -- each contains the extracted logic from `index.js`
2. **Ready for incremental migration** -- swap `exports.X` in `index.js` to `require('./src/module').X`
3. **Independently testable** -- each module can be unit tested in isolation

### To migrate a function:
1. Find the function in `index.js`
2. Replace the implementation with: `exports.functionName = require('./src/module').functionName;`
3. Test with `firebase emulators:start --only functions`
4. Deploy: `firebase deploy --only functions`

## Deployment

```bash
# Local development
firebase emulators:start --only functions

# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:dispatchSOS
```

## Secrets

- `LIVEKIT_API_SECRET` -- GCP Secret Manager (required for LiveKit functions)
- `GEMINI_API_KEY` -- Environment variable
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER` -- Environment variables
