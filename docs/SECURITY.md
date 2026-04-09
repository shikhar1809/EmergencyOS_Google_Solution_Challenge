# Security model

## Firestore

- Access is enforced with **Firestore Security Rules** (see `firestore.rules` in the repo / Firebase console).  
- Incidents and PII-heavy documents must be **scoped by role** (victim, volunteer, fleet operator, admin) and **least privilege**.  
- Validate `request.auth != null` where appropriate; avoid world-writable collections.

## Authentication

- **Firebase Auth** (Google, phone OTP, anonymous for drills / console entry as implemented).  
- **SOS PIN** (client + rules) restricts exiting active SOS flows—treat PIN hashes as sensitive.

## App Check

- Enable **Firebase App Check** for production builds to reduce abuse of callable functions and APIs.

## Secrets

- **Gemini**, **Twilio**, **LiveKit**, and **Maps** keys belong in **Cloud Functions config / Secret Manager**, not in the client.  
- Client uses only **dart-define** or public keys where appropriate (e.g. Maps browser key with HTTP referrer restrictions).

## Consent

- Emergency data consent is surfaced in-app before SOS dispatch; document retention and purpose in your privacy policy.

## analytics_events

- If using `UsageAnalyticsService`, rules should allow **authenticated append-only** writes and **admin-read** for dashboards.
