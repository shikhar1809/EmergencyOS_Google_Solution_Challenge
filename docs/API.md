# Cloud Functions & HTTP API (reference)

Implementation lives in `functions/index.js`. This document is a **maintainer-facing catalogue**; exact names and payloads should be verified against exports in that file.

## Patterns

- **Callable functions** (`onCall`): invoked from the client via `FirebaseFunctions.instance.httpsCallable('name')` (or equivalent). Expect JSON-serializable request/response bodies and Firebase Auth context when secured.
- **HTTP functions** (`onRequest`): REST-style endpoints for webhooks or integrations; validate auth (App Check / tokens) before trusting input.
- **Firestore triggers** (`onDocumentCreated`, `onDocumentUpdated`): react to `sos_incidents` and other collections.

## Endpoint families (examples)

Groupings below map to **families** of exports in `functions/index.js` (names will vary by version):

1. **Lifeline / LiveKit** — dispatch tokens, room lifecycle, agent hooks  
2. **Notifications** — FCM fan-out for incidents, fleet, volunteers  
3. **Triage / AI** — Gemini-backed classification or coaching (when enabled)  
4. **SMS / telephony** — Twilio-backed flows when environment variables are set  
5. **Leaderboard / gamification** — server-side scoring or aggregation helpers  
6. **Hospital / ops** — bed availability or assignment helpers (demo vs production)  

### Documenting a single endpoint

For each export, record:

| Field | Description |
|-------|-------------|
| Name | Callable / HTTP / trigger name |
| Auth | Required roles / App Check |
| Input | JSON schema |
| Output | JSON schema |
| Errors | `HttpsError` codes |

> **Action item:** Run `grep -E "exports\\.|onCall\\(|onRequest\\(" functions/index.js` and extend this file with one table per export for a full Solution Challenge appendix.
