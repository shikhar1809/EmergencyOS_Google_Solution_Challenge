<div align="center">

<img src="logo.png" alt="EmergencyOS" width="140" />

# EmergencyOS

### Designed to Save Lives.

*An AI-powered, offline-first emergency response platform — built for the next minute that matters.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Platform-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini 2.5 Flash](https://img.shields.io/badge/Gemini_2.5_Flash-AI-4285F4?logo=google&logoColor=white)](https://ai.google.dev)
[![Google Maps](https://img.shields.io/badge/Google_Maps-Platform-34A853?logo=googlemaps&logoColor=white)](https://developers.google.com/maps)
[![LiveKit](https://img.shields.io/badge/LiveKit-WebRTC-FF3C00?logo=webrtc&logoColor=white)](https://livekit.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-0BDA51)](LICENSE)
[![Google Solution Challenge 2026](https://img.shields.io/badge/Google_Solution_Challenge-2026-4285F4)](https://developers.google.com/community/gdsc-solution-challenge)

**Google Solution Challenge 2026 · Open Track — Rapid Emergency Response**

</div>

---

## The Night That Built This Product

It was an ordinary evening at home when my mother suddenly clutched her chest and slid down against the wall. Her face was pale, her breathing was shallow, and I was alone. I did what any Indian kid is taught to do first — I dialed **112**.

> *"The call connected. Then a hold tone. Then silence. Then the line dropped."*

I dialed **102** for the state ambulance. **"Number busy."**
I dialed the local private ambulance number I had saved in my phone a year ago. **"The number you are trying to reach is not in service."**
I tried two more from a Google search. **One didn't pick up. The other said they had no vehicle free for the next 40 minutes.**

Every clock in the house suddenly felt very loud.

With the neighbor's help, I pushed my mother into a car and drove to the **nearest hospital** — eight minutes away. The triage nurse took one look at the ECG and said the words you never want to hear:

> *"We are not equipped for this. You have to take her to a cardiac center. Now."*

No patient transfer ambulance. No stretcher protocol. No phone call ahead to the next hospital. We went back into the same car. **Twenty-two more minutes** of honking through traffic until we finally reached a tertiary cardiac hospital. The doctors admitted her. They asked for her medical history. I had nothing — no paper, no app, no records. I answered from memory while she was being wheeled into the cath lab.

By God's grace, **she survived.** I sat outside the ICU that night and couldn't stop replaying one thought:

**How many families are not that lucky?**

That night, I didn't grieve. I got angry. And I started building.

**EmergencyOS was born that night.**

---

## The Gaps I Saw — And The Numbers Behind Them

What I lived through wasn't bad luck. It is the **default emergency experience** for most of India and the developing world. The data is brutal:

| Reality | Number |
|---|---|
| Indians who die every year from **delayed emergency medical care** | **~3 million** <sup>(NCRB, AIIMS trauma reports)</sup> |
| Deaths in road accidents in India per year — most in the **Golden Hour** | **~1,68,000** (2022) <sup>(MoRTH)</sup> |
| % of cardiac arrest victims who survive outside a hospital in India | **< 1 %** <sup>(vs. 10–12 % in the US / 25 % in Seattle)</sup> |
| Drop in cardiac arrest survival **per minute** without CPR/defibrillation | **~10 %** <sup>(American Heart Association)</sup> |
| Average urban ambulance response time in Indian Tier-2/3 cities | **25–45 minutes** <sup>(WHO SEARO 2022)</sup> |
| Target response time in Germany / UK | **8–12 minutes** |
| % of Indian ambulance calls that reach the **wrong-specialty hospital** | **~30 %** forcing a second transfer |
| % of patients who arrive at the hospital with **zero accessible medical history** | **~85 %** |
| Indians who still rely on 2G / feature phones (no smartphone apps) | **~25 crore (250 million)** |

The real killer isn't the disease. It is the **minutes** we lose between the symptom and the right bed. EmergencyOS exists to close that gap — with intelligence, redundancy, and grace.

---

## The Solution — EmergencyOS

> **Tagline:** *Designed to save lives.*

EmergencyOS is not a "call an ambulance" app. It is an **end-to-end emergency operating system** that connects six roles — **Victim → Citizen Volunteer → EMS Fleet → Hospital → Ops Command → Emergency Contact** — into one real-time, AI-coordinated, offline-capable command mesh.

It is built on Google Cloud, Firebase, Gemini 2.5 Flash, Google Maps Platform, and LiveKit WebRTC — and deployed as **three synchronized apps** that share a single live brain.

### One sentence for a grandmother

*"You press one button. The right ambulance, the right hospital, the right volunteer nearby, and the right AI doctor's voice all arrive together — even if there is no internet."*

---

## The User Flow — Ten Seconds to Rescue

This is exactly what happens when someone taps the red SOS button inside EmergencyOS.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│   0s   VICTIM   ─ Hold SOS 2 seconds  ───┐                                      │
│                                          │  (or send a GeoSMS if no internet)   │
│                                          ▼                                      │
│   1s   APP      ─ Capture GPS, voice, medical card, emergency contact           │
│                                          │                                      │
│                                          ▼                                      │
│   2s   CLOUD    ─ dispatchSOS() Cloud Function fires                            │
│                   ├─ Gemini triage vision → incident type, severity, services   │
│                   ├─ Hex-grid hospital scorer → top N hospitals by              │
│                   │   ring distance + specialty + bed availability              │
│                   ├─ FCM Layer 1: geo-multicast to volunteers within 20 km      │
│                   ├─ FCM Layer 2: topic broadcast "sos_alerts"                  │
│                   ├─ FCM Layer 3: all-user fallback  (no silent drops)          │
│                   └─ Twilio SMS to emergency contact + 2G phones                │
│                                          │                                      │
│                                          ▼                                      │
│   5s   VOLUNTEER ─ Phone rings, screen shows incident card, accepts in 1 tap    │
│                    LIFELINE AI starts voice-guiding CPR / bleeding / burns      │
│                                          │                                      │
│                                          ▼                                      │
│  10s   HOSPITAL  ─ Gets a 2-minute acceptance window on the dashboard           │
│                    If declined / timeout → auto-escalates to next hospital      │
│                                          │                                      │
│                                          ▼                                      │
│  30s   FLEET     ─ Nearest available ambulance gets a 3-minute window           │
│                    Operator taps Accept → Google Maps turn-by-turn opens        │
│                                          │                                      │
│                                          ▼                                      │
│    ∞   OPS       ─ Hex-grid command center tracks everything in real time       │
│                    Victim's lock screen shows live ETA, ambulance, volunteer    │
│                    Emergency contact gets SMS updates automatically             │
│                    Hospital pre-loads patient's medical history from cloud      │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

No human operator is required anywhere in this chain. Every step is idempotent, observable, and has an escalation timer.

---

## Three Apps. One Brain.

EmergencyOS ships as **three separately compiled and hosted apps** that all share the same Firestore backend, the same dispatch engine, and the same AI.

<div align="center">

| App | Target | Who uses it | Entry point |
|---|---|---|---|
| **EmergencyOS — Main App** | Android · iOS · Web | Citizens, patients, volunteers, families | `lib/main.dart` |
| **Command Center — Admin Dashboard** | Web | Operations staff, government command rooms | `lib/main_admin.dart` |
| **Fleet Panel — EMS Operator App** | Web | Ambulance drivers and dispatchers | `lib/main_fleet.dart` |

</div>

### How they connect

```
                        ┌──────────────────────────────────────────┐
                        │         ONE LIVE BRAIN (Firestore)        │
                        │  sos_incidents · hospitals · fleet units  │
                        │  volunteers · assignments · bridges       │
                        └──────────────────────────────────────────┘
                                   ▲          ▲          ▲
                                   │          │          │
              live listeners       │          │          │    live listeners
              + FCM + LiveKit      │          │          │    + FCM + LiveKit
                                   │          │          │
            ┌──────────────────────┴─┐ ┌──────┴─────┐ ┌──┴──────────────────┐
            │   Main App             │ │  Admin     │ │   Fleet Panel        │
            │   (Flutter)            │ │  Dashboard │ │   (Web)              │
            │                        │ │  (Web)     │ │                      │
            │ • Tap-SOS              │ │            │ │ • Incoming dispatches│
            │ • LIFELINE AI chat     │ │ • Hex-grid │ │ • Accept / Decline   │
            │ • Voice co-pilot       │ │   command  │ │   with 3-min timer   │
            │ • Live tracking        │ │   map      │ │ • Turn-by-turn nav   │
            │ • Volunteer consign    │ │ • Incident │ │ • Voice comms bridge │
            │ • AED finder           │ │   inspector│ │   (operation +       │
            │ • Family tracker link  │ │ • Fleet &  │ │    emergency rooms)  │
            │ • Offline SOS (SMS)    │ │   hospital │ │ • Fleet heartbeat    │
            │ • 19-level CPR        │ │   mgmt     │ │ • Unit handoff       │
            │   training arena       │ │ • System   │ │                      │
            │                        │ │   observ.  │ │                      │
            │                        │ │ • Impact   │ │                      │
            │                        │ │   dashboard│ │                      │
            └────────────────────────┘ └────────────┘ └──────────────────────┘
```

**Every click in one app is visible in the other two within ~500ms** — because they all listen to the same Firestore documents and share the same LiveKit rooms for voice.

---

## The Use of AI — Gemini as a System, Not a Chatbot

AI in EmergencyOS is not a demo feature bolted on. **Gemini 2.5 Flash is used at four distinct points in the lifecycle of every incident.**

| # | Where | What Gemini does |
|---|---|---|
| 1 | **Intake — Triage Vision** | Victim or bystander can snap a photo. Gemini Vision classifies incident type (cardiac / RTA / fire / burn / fall / drowning), estimates severity, detects visible blood and hazards, and returns a confidence score. Drives which services are dispatched. |
| 2 | **On-scene — LIFELINE First-Aid Copilot** | A voice & chat AI that walks a panicked bystander through CPR, bleeding control, burns, choking, seizures, strokes, anaphylaxis, drowning — step by step, in their native language. Powered by Gemini 2.5 Flash via Cloud Function, with a local offline knowledge base as fallback. |
| 3 | **Command — Situation Brief** | Every 5 minutes, for every active incident, a Cloud Function regenerates a Gemini scene brief from volunteer reports + photos + video + status history. Ops staff always see one paragraph of fresh ground truth. |
| 4 | **Analytics — Ops AI Chat** | The admin dashboard has an embedded Gemini chat that can answer *"which hex had the slowest response last week?"* or *"summarize all cardiac incidents in zone 3 today"* — grounded on live Firestore analytics. |

### LIFELINE Copilot — the always-on voice assistant

Every logged-in user also has a **personal voice agent** on `copilot_{uid}` — a private LiveKit WebRTC room powered by **OpenAI Realtime** with `@livekit/noise-cancellation-node`. It has tools to:

- Read which screen the user is on and coach them through it hands-free
- Look up any medical protocol on demand
- Request an SOS trigger (the user must confirm) — so an elderly user can literally say *"call an ambulance, I think I'm having a heart attack"* and the chain fires.

---

## Reliability — Engineered for the Worst Day

Emergency systems fail people exactly when they are needed most. EmergencyOS is designed with the assumption that **everything will go wrong.**

| Failure mode | How EmergencyOS handles it |
|---|---|
| **Volunteer's FCM token is stale** | 3 independent FCM layers (geo, topic, all-users). One failure never silences the others. |
| **Hospital ignores the dispatch** | 2-minute acceptance window → auto-escalates to the next best hospital. `hospitalDispatchEscalation` runs every minute. |
| **Ambulance operator doesn't respond** | 3-minute window → auto-escalates to the next-nearest fleet unit. `ambulanceDispatchEscalation` runs every minute. |
| **Gemini API key is down** | Local offline first-aid knowledge base (19 levels, curriculum-grade) keeps serving guidance. |
| **Google Maps WebGL fails** | `flutter_map` CPU-renderer fallback kicks in. |
| **User has no mobile data — only 2G SMS** | Twilio GeoSMS webhook (`parseSmsGateway`) creates a real Firestore incident from a text message. Victim gets SMS status back. |
| **Rate-limit spam** | Rate-limit **flags** an incident but **never blocks dispatch**. Real emergencies cannot be missed to prevent abuse. This is the single most important design rule in the system. |
| **App crashes mid-SOS** | `sos_incidents` doc is durable in Firestore — re-opening the app resumes the same live ETA. |
| **Incident gets forgotten** | Hard 1-hour TTL → `expireStaleSosIncidents` archives and notifies. No zombie incidents. |
| **Third-party sensor system** | `onExternalIncidentTrigger` HTTP webhook with shared-secret auth lets IoT devices (AEDs, fall detectors, partner apps) create incidents. |

**Every state change is observable.** The admin dashboard's `ops_dashboard_alerts` feed shows every dispatch event live — hospital notified, declined, exhausted, no beds, ambulance accepted, ambulance expired, volunteer accepted, volunteer on scene.

---

## Offline Capabilities — Because Bandwidth Disappears in Disasters

When a flood, fire, or blackout hits, cellular coverage is the first thing to collapse. EmergencyOS is one of the few emergency apps that actually works when the network is broken.

| Subsystem | Offline behaviour |
|---|---|
| **Firestore** | Offline persistence enabled, 50 MB cache. SOS writes queue and sync when signal returns. |
| **`OfflineCacheService`** | Pre-caches the user's active incident, medical history, emergency contacts, and last-known ambulance position. |
| **`OfflineKnowledgeService`** | Full 19-level first-aid curriculum (CPR, choking, bleeding, burns, seizure, stroke, allergic reactions) available in 12 languages, zero network. |
| **`OfflineMapPackService`** | User can pre-download map tiles for their home zone. Incident map keeps rendering. |
| **`OfflineSosStatusService`** | If SOS fails to upload, it is queued and retried on reconnect — and an SMS is sent in parallel. |
| **TTS voice guidance** | Reads first-aid steps aloud when the screen is unreadable (dust, smoke, blood, motion). |
| **SMS GeoSMS gateway** | A user with no app at all can SMS coordinates + incident type to the gateway number and trigger a full dispatch. |
| **Native feature-phone reach** | Emergency contacts receive SMS updates — they don't need the app installed. |

---

## Dashboards — One Screen That Runs a City

The **Command Center (Admin Dashboard)** is the nerve center. This is what a city's emergency control room looks like inside EmergencyOS:

| Screen | What you see |
|---|---|
| **Command Center Map** | Hex-grid overlay (flat-top axial coordinates) over a live city map. Every active incident, every volunteer, every ambulance, every hospital with bed count. Color-coded by severity. Zoom in — see the details. Click a hex — see everyone in it. |
| **Incident Inspector** | Focus any incident. Full dispatch chain, hospital acceptance trail, fleet assignment state, volunteer roster, scene photos, Gemini situation brief, voice-bridge join button. |
| **Admin Analytics** | Response time histogram, incident type breakdown, zone heatmaps, volunteer XP trends — rendered with `fl_chart`. |
| **Fleet Management** | All ambulance units, 90-second heartbeat TTL, stationed hospital, call sign, vehicle type, live availability. |
| **Hospital Management** | All hospitals with bed availability, specialty map, onboarding wizard, pre-uploaded medical record index. |
| **Volunteer Management** | XP, level, lives saved, profile, elite tier flags, verification state. |
| **System Observatory** | Live health check — Firestore latency, LiveKit rooms, Twilio credits, Gemini key, FCM token count. A single "green / red" board for the ops lead. |
| **Impact Dashboard** | Platform-level outcomes — lives helped, incidents resolved, average response time, fastest volunteer, most-dispatched hospital. |
| **Master Comms Net** | `comms_command_net` LiveKit room — command-level voice override on *any* incident. The ops lead can speak into any active bridge. |

Hospitals get their own slice — a **Hospital Bridge** view showing the incoming patient, required services vs. capacity, scene photos, pre-loaded medical history, and a 2-minute dispatch acceptance button.

---

## Feature Highlights

<details open>
<summary><b>One-Tap SOS + AI Triage</b></summary>

- Hold-to-confirm SOS to prevent accidents
- GPS + voice capture + medical card + emergency contact auto-attached
- Gemini Vision triage from scene photo → incident type, severity, services needed, confidence
- Active SOS lock screen: live ambulance ETA, volunteer name, hospital name
- 3-layer FCM dispatch (geo / topic / all-users) — fail-open, never silent
</details>

<details>
<summary><b>LIFELINE — AI First-Aid Copilot</b></summary>

- Chat + voice + photo triage
- Gemini 2.5 Flash cloud-side, offline knowledge base fallback
- 19-level gamified training arena (XP, levels, lives-saved leaderboard)
- Emergency mode toggle — switch from learning to live guidance
- 12 Indian languages with native-locale TTS
</details>

<details>
<summary><b>Intelligent Hospital Dispatch (Hex-Grid)</b></summary>

- Flat-top axial hex grid over the city (Lucknow ops center anchor by default)
- Three dispatch tiers: same hex → rings 1–5 → specialists beyond
- Scoring: hex distance + specialty match + bed availability + haversine km
- Specialty bonus (cardiac for heart attack, trauma for RTA, burns for fires)
- 2-minute acceptance window, automatic escalation, never deadlocks
</details>

<details>
<summary><b>EMS Fleet Operations</b></summary>

- Dedicated `/fleet` web panel for ambulance operators
- 3-minute dispatch acceptance with auto-escalation
- Two dedicated LiveKit voice rooms per incident:
  - `commsop_{id}` — hospital ↔ EMS operation coordination
  - `commsem_{id}` — victim ↔ EMS voice bridge
- 90-second availability heartbeat, call-sign + stationed hospital tracking
</details>

<details>
<summary><b>Volunteer Response Network</b></summary>

- Real-time GPS presence broadcasting for available volunteers
- Geo-radius alert (20 km) — one-tap accept/decline
- On-scene check-in feeds Gemini situation briefs
- Post-incident feedback drives XP and the leaderboard
- **Elite tier** (Level 10+ or 5 lives saved + 1000 XP) gets priority voice in the emergency bridge
- Push-to-talk channel (`ptt_channels`) for all responders on an incident
</details>

<details>
<summary><b>Family Tracker</b></summary>

- One-tap share link: `/family-tracker/{id}?t={token}`
- Opens in a browser — no app install needed
- Live location, ETA, ambulance call sign, status timeline
- Auto-SMS updates: *"Volunteer accepted"*, *"Ambulance 4 min away"*, *"Admitted at XYZ Hospital"*
</details>

<details>
<summary><b>SMS Offline Emergency Gateway</b></summary>

- Twilio webhook (`parseSmsGateway`) with signature verification
- Parses GeoSMS URL format → coordinates, incident type, victim count
- Creates a real Firestore incident; full dispatch chain fires
- Reply SMS carries ETA and status updates back to 2G phones
</details>

<details>
<summary><b>Emergency Drill Mode</b></summary>

- Full end-to-end simulation without touching real incidents
- `/drill/*` route tree, separate data namespace
- Used for city-scale community preparedness drills
</details>

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                     │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│   │  Main App        │  │  Admin Console   │  │  Fleet Panel     │             │
│   │  Flutter         │  │  Flutter Web     │  │  Flutter Web     │             │
│   │  Android/iOS/Web │  │  /ops-dashboard  │  │  /fleet          │             │
│   └────────┬────────┘  └────────┬────────┘  └────────┬────────┘             │
└────────────┼───────────────────┼────────────────────┼──────────────────────┘
             │                   │                    │
┌────────────▼───────────────────▼────────────────────▼──────────────────────┐
│                             FIREBASE BACKEND                                │
│   Auth  ·  Firestore (real-time + offline 50 MB cache)  ·  FCM (3-layer)    │
│   App Check (Play Integrity + DeviceCheck + reCAPTCHA v3)  ·  Storage       │
│   Crashlytics  ·  Performance  ·  Hosting (3 targets)                       │
└───────────────────────────────────────────────────────────────────────────────┘
                                     │
┌────────────────────────────────────▼──────────────────────────────────────┐
│                     CLOUD FUNCTIONS v2 (Node.js 18)                         │
│   dispatchSOS · dispatchHospitalInHex · lifelineChat                        │
│   analyzeTriageImage · generateSituationBriefForIncident                    │
│   acceptHospitalDispatch · declineHospitalDispatch                          │
│   acceptAmbulanceDispatch · ambulanceDispatchEscalation                     │
│   getLivekitToken · ensureEmergencyBridge · ensureCopilotAgent              │
│   parseSmsGateway · onIncidentUpdate · expireStaleSosIncidents              │
│   updateLeaderboardOnIncidentChange · onExternalIncidentTrigger             │
│   + 20 more — 3,358 lines of production logic                               │
└─────┬─────────────────────┬────────────────────────┬─────────────────────┘
      │                     │                        │
┌─────▼──────────┐  ┌───────▼────────────┐  ┌────────▼───────┐
│  Gemini 2.5    │  │  LiveKit WebRTC    │  │  Twilio SMS    │
│  Flash         │  │  SFU + Agents      │  │  Gateway       │
│  • Triage      │  │  • emergency_bridge│  │  • Victim ETA  │
│  • LIFELINE    │  │  • copilot_{uid}   │  │  • Contact SMS │
│  • Scene brief │  │  • commsop / em    │  │  • GeoSMS in   │
│  • Ops chat    │  │  • comms_command   │  │                │
└────────────────┘  └────────────────────┘  └────────────────┘
                           │
                  ┌────────▼─────────┐
                  │  Google Maps     │
                  │  Platform        │
                  │  Directions      │
                  │  Places          │
                  │  Geocoding       │
                  └──────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile & Web Apps** | Flutter 3.x · Dart · go_router v17 · Riverpod 3 |
| **UI** | Material 3 · flutter_animate · Lottie · shimmer · fl_chart |
| **Maps** | google_maps_flutter · flutter_map · geolocator · geocoding · flutter_polyline_points |
| **AI Brain** | **Gemini 2.5 Flash** (triage vision, LIFELINE chat, scene brief, ops analytics) |
| **Voice AI** | LiveKit Agents (TypeScript) · OpenAI Realtime · @livekit/noise-cancellation-node |
| **WebRTC** | livekit_client (Flutter) · livekit-server-sdk (Node.js) |
| **Backend** | **Firebase Cloud Functions v2** (Node.js 18) — 3,358 LOC |
| **Database** | **Cloud Firestore** — real-time + offline persistence (50 MB cache) |
| **Auth** | **Firebase Auth** — Google Sign-In, Email/Password, Anonymous, reCAPTCHA v3 |
| **Push** | **Firebase Cloud Messaging** — 3-layer dispatch |
| **Storage** | **Firebase Storage** — scene photos, triage images, incident video |
| **SMS** | Twilio — inbound GeoSMS webhook + outbound ETA & contact alerts |
| **Security** | Firebase App Check (Play Integrity + DeviceCheck + reCAPTCHA v3) |
| **Monitoring** | Firebase Crashlytics · Firebase Performance |
| **Localization** | flutter_localizations · intl · 12 Indian languages |
| **Platforms** | Android · iOS · Web (3 hosted targets) · Linux · Windows · macOS |

---

## Firestore Collections

```
sos_incidents/                         Active emergencies (1h TTL → archived)
sos_incidents_archive/                 Closed incidents (leaderboard source)
ops_hospitals/                         Hospital registry (lat, lng, beds, specialties, hex)
ops_incident_hospital_assignments/     Hospital dispatch chain state per incident
ops_fleet_units/                       Ambulance units (90s heartbeat TTL)
ops_fleet_assignments/{cs}/pending/    Per-operator dispatch queue
users/                                 User profiles, medical history, FCM tokens
volunteers/                            Real-time GPS presence
leaderboard/                           Server-computed volunteer rankings
ptt_channels/{id}/messages/            Push-to-talk voice transcripts
livekit_bridges/                       Emergency bridge dispatch records
livekit_copilot_dispatches/            Copilot rate-limit records
ops_dashboard_alerts/                  Live ops event feed
ops_health_metrics/                    System counters
sos_dispatch_limits/                   Per-user geo-dispatch rate state
aeds/                                  AED defibrillator locations
preparedness_events/                   Community readiness log
webhook_events/                        Third-party trigger audit log
```

---

## Cloud Functions at a Glance

| Function | Trigger | Purpose |
|---|---|---|
| `dispatchSOS` | Firestore onCreate `sos_incidents/{id}` | 3-layer FCM dispatch + hospital hex routing |
| `dispatchHospitalInHex` | Called by `dispatchSOS` | Score hospitals by hex ring + specialty |
| `hospitalDispatchEscalation` | Scheduled every 1 min | Auto-escalate if hospital doesn't accept in 2 min |
| `acceptHospitalDispatch` / `declineHospitalDispatch` | Callable | Hospital response → trigger fleet or escalate |
| `onHospitalAssignmentAcceptedDispatchAmbulance` | Firestore onUpdate | Notify nearest fleet units |
| `acceptAmbulanceDispatch` | Callable | Operator accepts → EMS en-route |
| `ambulanceDispatchEscalation` | Scheduled every 1 min | Escalate stale fleet assignments |
| `lifelineChat` | Callable | Gemini LIFELINE AI (chat / analytics / training) |
| `analyzeTriageImage` / `analyzeIncidentVideo` | Callable | Gemini vision triage |
| `generateSituationBriefForIncident` | Callable | Gemini scene brief |
| `refreshSituationBriefsScheduled` | Scheduled every 5 min | Keep briefs fresh |
| `getLivekitToken` / `getCopilotLivekitToken` | Callable | Mint WebRTC tokens |
| `ensureEmergencyBridge` / `ensureCopilotAgent` | Callable | Dispatch AI voice agents |
| `parseSmsGateway` | HTTP (Twilio webhook) | Offline SMS → incident |
| `onIncidentUpdate` | Firestore onUpdate | SMS ETA updates back to victim |
| `notifyEmergencyContactOnUpdate` | Firestore onUpdate | SMS updates to emergency contact |
| `updateLeaderboardOnIncidentChange` | Firestore onCreate archive | Server-side leaderboard aggregation |
| `expireStaleSosIncidents` | Scheduled every 5 min | 1h TTL → archive |
| `onExternalIncidentTrigger` | HTTP (partner webhook) | Third-party incident/AED ingestion |
| `getOpsSystemHealth` | Callable | Integration health check |

(Plus ~10 more escalation / cleanup functions. See `functions/index.js` — 3,358 lines.)

---

## LiveKit Voice Rooms

| Room | Purpose | Participants |
|---|---|---|
| `emergency_bridge_{incidentId}` | Victim ↔ LIFELINE AI ↔ Volunteers ↔ EMS | victim · accepted_volunteer · volunteer_elite · ems_fleet · emergency_desk · emergency_contact |
| `copilot_{uid}` | Per-user persistent voice assistant | user + Copilot AI agent |
| `commsop_{incidentId}` | Operation voice bridge | Hospital staff + EMS operator |
| `commsem_{incidentId}` | Emergency voice bridge | Hospital emergency desk + EMS |
| `comms_command_net` | Master command voice net | Admin master console only |

Token TTL: 6 hours for emergency bridges, 12 hours for comms bridges.

---

## Local Setup

### Prerequisites

- Flutter SDK `^3.11.3`
- Node.js 18+
- Firebase CLI
- A Firebase project with Firestore, Auth, FCM, Storage, and App Check enabled

### 1. Clone & install

```bash
git clone https://github.com/shikhar1809/EmergencyOS_Google_Solution_Challenge.git
cd EmergencyOS_Google_Solution_Challenge
flutter pub get
```

### 2. Configure Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 3. Cloud Functions

```bash
cd functions
npm install
cp .env.example .env
# Fill in: GEMINI_API_KEY, LIVEKIT_URL, LIVEKIT_API_KEY,
#         TWILIO_* (optional), WEBHOOK_SHARED_SECRET (optional)
firebase functions:secrets:set LIVEKIT_API_SECRET
firebase deploy --only functions
```

### 4. LiveKit Agents

```bash
# Lifeline voice agent (reads important comms in emergency room)
cd livekit-agent/lifeline-agent
npm install && cp .env.example .env.local && npm run dev

# Copilot voice agent (persistent per-user assistant)
cd ../copilot-agent
npm install && cp .env.example .env.local && npm run dev
```

### 5. Run the three apps

```bash
# Main citizen app
flutter run -t lib/main.dart

# Admin / command center
flutter run -t lib/main_admin.dart

# Fleet operator panel
flutter run -t lib/main_fleet.dart
```

### 6. Deploy to Firebase Hosting (all three targets)

```bash
flutter build web --release --dart-define RECAPTCHA_SITE_KEY=your_key
# Repeat with --target lib/main_admin.dart --output build/web-admin
# Repeat with --target lib/main_fleet.dart  --output build/web-fleet
firebase deploy --only hosting
```

---

## Environment Variables

### `functions/.env`

| Variable | Required | Description |
|---|---|---|
| `GEMINI_API_KEY` | Yes | Google Generative AI key |
| `LIVEKIT_URL` | Yes* | `wss://your-project.livekit.cloud` |
| `LIVEKIT_HTTP_URL` | Yes* | Alternative to `LIVEKIT_URL` |
| `LIVEKIT_API_KEY` | Yes | LiveKit API key |
| `LIVEKIT_API_SECRET` | Yes | LiveKit secret (Firebase Secret Manager) |
| `LIFELINE_LIVEKIT_AGENT_NAME` | No | Default: `lifeline` |
| `COPILOT_LIVEKIT_AGENT_NAME` | No | Default: `copilot` |
| `TWILIO_ACCOUNT_SID` | Optional | SMS gateway |
| `TWILIO_AUTH_TOKEN` | Optional | Twilio auth |
| `TWILIO_PHONE_NUMBER` | Optional | Sender number |
| `WEBHOOK_SHARED_SECRET` | Optional | Third-party incident webhook |

### LiveKit Agents (`.env.local`)

`LIVEKIT_URL` · `LIVEKIT_API_KEY` · `LIVEKIT_API_SECRET` · `OPENAI_API_KEY`

---

## Key Design Decisions (Why it is built this way)

**Why hex-grid dispatch and not simple radius?**
Hex grids have uniform neighbor distance in all 6 directions — no nearest-corner bias. The flat-top axial coordinate system allows precise *ring-0 → ring-5* escalation with consistent km spacing, matching how real cities actually zone themselves.

**Why 3-layer FCM and not just one?**
Layer 1 (geo-multicast) may fail if volunteers' tokens are stale. Layer 2 (topic) guarantees subscribers get it. Layer 3 (all-users) is the last-ditch safety net. Each layer runs **independently** — one failure never silences another.

**Why fail-open on SOS rate limiting?**
Real emergencies cannot be missed for the sake of preventing spam. Rate-limit violations are *flagged* — dispatch still fires. Ops can review flagged incidents afterwards.

**Why three separate hosted web targets?**
Admin and fleet have different root routes, different auth guards, different navigation shells, and even different Firebase options. Separate builds allow independent deploys and role-based CDN isolation.

**Why LiveKit over proprietary WebRTC?**
LiveKit is open, self-hostable, and exposes an `AgentDispatchClient` that lets Cloud Functions push AI voice agents into rooms — critical for a system that must not depend on a single commercial provider during a disaster.

---

## 12 Languages, One Voice

App UI, LIFELINE responses, and TTS voice guidance available in:

**English · हिन्दी · தமிழ் · తెలుగు · ಕನ್ನಡ · മലയാളം · বাংলা · मराठी · ગુજરાતી · ਪੰਜਾਬੀ · ଓଡ଼ିଆ · اردو**

Gemini responds in the user's language via `replyLocale`. TTS uses the BCP-47 locale for native speech synthesis. To regenerate:

```bash
export GOOGLE_TRANSLATE_API_KEY=your_key
python scripts/generate_dashboard_translations.py
```

---

## Screens

Sample screenshots are in `LiveLine_Images/` and `Map_Marker/`. Highlights:

- SOS slide-to-confirm + active locked screen with live ETA
- Hex-grid command center with zoomed incident inspector
- LIFELINE training arena — 19 gamified levels
- Fleet incoming dispatch + turn-by-turn
- Hospital bridge with patient record preload
- Family tracker web link

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Especially welcome:

- Additional language translations (`lib/core/l10n/`)
- New LIFELINE training levels (`lib/features/ai_assist/domain/lifeline_training_levels.dart`)
- Hospital and AED database integrations for your city
- OSRM / offline routing improvements

---

## License

MIT — see [LICENSE](LICENSE).

---

## Acknowledgements

Built on the shoulders of giants: **Google Cloud · Firebase · Gemini 2.5 Flash · Google Maps Platform · LiveKit · OpenAI Realtime · Twilio · Flutter**.

Submitted to the **Google Solution Challenge 2026** — *Open Track, Rapid Emergency Response.*

---

<div align="center">

### **Built by Shikhar Shahi**

*For every mother, every father, every child, every stranger —*
*whose next minute deserves to count.*

**EmergencyOS — Designed to save lives.**

</div>
