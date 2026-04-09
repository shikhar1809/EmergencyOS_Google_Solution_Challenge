# Hospital Bridge — Architecture Document

## Overview

The **Hospital Bridge** is a Discord-style real-time communications hub connecting hospital dashboard admins with each other and with the Master Admin. It provides persistent voice channels, text chat per channel, and full Discord-like voice controls (mute, deafen, voice activity detection) — all powered by LiveKit.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Server** | A top-level grouping — each hospital gets its own server; Master Admin has a "Command" server |
| **Channel** | A voice + text room within a server (e.g., `#general`, `#emergency-ops`, `#bed-coordination`) |
| **Voice State** | Per-user per-channel: mic muted/unmuted, deafened (can't hear others), speaking/not-speaking |
| **Text Chat** | Real-time messages via LiveKit data channels, scoped to the active voice room |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        EmergencyOS Client (Flutter)                      │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │              Hospital Bridge Feature Module                         │  │
│  │                                                                     │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │  │
│  │  │ BridgeServer │  │ BridgeChannel│  │  BridgeVoiceState        │  │  │
│  │  │  Screen       │  │  Screen       │  │  (mute/deafen/speaking)  │  │  │
│  │  │              │  │              │  │                          │  │  │
│  │  │ - Server list│  │ - Voice strip│  │  - micMuted              │  │  │
│  │  │ - Channels   │  │ - Text chat  │  │  - deafened              │  │  │
│  │  │ - Create/Edit│  │ - Members    │  │  - isSpeaking            │  │  │
│  │  └──────┬───────┘  └──────┬───────┘  └────────────┬─────────────┘  │  │
│  │         │                  │                       │                │  │
│  │  ┌──────▼──────────────────▼───────────────────────▼─────────────┐  │  │
│  │  │              HospitalBridgeService                             │  │  │
│  │  │                                                                 │  │  │
│  │  │  - connectChannel() → LiveKit Room                             │  │  │
│  │  │  - sendChatMessage() → data channel publish                    │  │  │
│  │  │  - toggleMic() / toggleDeafen()                                │  │  │
│  │  │  - createChannel() / deleteChannel() / renameChannel()         │  │  │
│  │  │  - listenParticipants() / listenActiveSpeakers()               │  │  │
│  │  │  - listenChatMessages() ← data channel events                  │  │  │
│  │  └──────────────────────────┬────────────────────────────────────┘  │  │
│  │                             │                                       │  │
│  └─────────────────────────────┼───────────────────────────────────────┘  │
│                                │                                          │
│  ┌─────────────────────────────▼───────────────────────────────────────┐  │
│  │                    LiveKit Client SDK                               │  │
│  │                                                                     │  │
│  │  Room ───► EventsListener                                           │  │
│  │           ├── ParticipantConnectedEvent                             │  │
│  │           ├── ParticipantDisconnectedEvent                          │  │
│  │           ├── ActiveSpeakersChangedEvent                            │  │
│  │           ├── TrackPublishedEvent / TrackSubscribedEvent            │  │
│  │           └── DataReceivedEvent (text chat)                         │  │
│  └─────────────────────────────┬───────────────────────────────────────┘  │
│                                │                                          │
└────────────────────────────────┼──────────────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   LiveKit Cloud Server   │
                    │                          │
                    │  Rooms:                  │
                    │  bridge_{hospitalId}_general      │
                    │  bridge_{hospitalId}_emergency    │
                    │  bridge_master_all_hospitals      │
                    │  bridge_master_urgent             │
                    │                          │
                    │  Data Channels:          │
                    │  Topic: bridge_chat      │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Firebase Cloud Functions │
                    │                          │
                    │  getHospitalBridgeToken   │
                    │  createBridgeChannel      │
                    │  deleteBridgeChannel      │
                    │  listBridgeChannels       │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │      Firestore           │
                    │                          │
                    │  bridge_servers           │
                    │  bridge_channels          │
                    │  bridge_memberships       │
                    └──────────────────────────┘
```

---

## Firestore Schema

### `bridge_servers` collection

```
bridge_servers/
  {serverId}/
    name: string                    // "City General Hospital" | "Master Command"
    type: "hospital" | "master"     // server type
    hospitalId: string?             // ops_hospitals doc id (null for master)
    icon: string?                   // emoji or color code
    createdAt: timestamp
    createdBy: string               // uid
```

### `bridge_channels` collection

```
bridge_channels/
  {channelId}/
    serverId: string                // parent server
    name: string                    // "general", "emergency-ops", "bed-coord"
    type: "voice"                   // voice+text channels (Discord style)
    position: number                // display order
    createdAt: timestamp
    createdBy: string               // uid
```

### `bridge_memberships` collection

```
bridge_memberships/
  {membershipId}/
    serverId: string
    userId: string                  // Firebase auth uid
    role: "admin" | "member"        // channel permissions
    joinedAt: timestamp
```

### Channel Naming Convention (LiveKit Rooms)

```
bridge_{serverId}_{channelId}
```

Examples:
- `bridge_hosp_abc123_general` — City General Hospital's general channel
- `bridge_master_all_hospitals` — Master admin's broadcast channel
- `bridge_master_urgent` — Master admin's urgent coordination channel

---

## Cloud Functions (New)

### `getHospitalBridgeToken`

```javascript
// Input
{ serverId, channelId, canPublishAudio }

// Output
{ token, url, roomName }

// Auth: requires hospital_bridge access (hospital admin or master)
// Role metadata: { serverId, channelId, userId, hospitalId, isAdmin }
```

### `createBridgeChannel`

```javascript
// Input
{ serverId, name, position }

// Output
{ channelId }

// Auth: server admin or master only
// Creates channel doc in Firestore
```

### `deleteBridgeChannel`

```javascript
// Input
{ channelId }

// Output
{ ok: true }

// Auth: server admin or master only
```

### `listBridgeChannels`

```javascript
// Input
{ serverId }

// Output
{ channels: [{ id, name, type, position }] }

// Auth: member of server
```

---

## Flutter Feature Module Structure

```
lib/features/hospital_bridge/
│
├── domain/
│   ├── bridge_server_model.dart          // BridgeServer, BridgeChannel, BridgeMembership
│   └── bridge_voice_state.dart           // VoiceState enum (mic, deafen, speaking)
│
├── data/
│   ├── bridge_repository.dart            // Firestore CRUD for servers/channels/memberships
│   └── bridge_token_provider.dart        // Cloud Functions wrapper for token generation
│
├── presentation/
│   ├── bridge_home_screen.dart           // Discord-style layout: server rail + channel list
│   ├── bridge_channel_screen.dart        // Voice channel view: strip + chat + controls
│   ├── bridge_server_list.dart           # Left server rail (Discord server icons)
│   ├── bridge_channel_list.dart          # Channel list within selected server
│   ├── bridge_create_channel_dialog.dart # Dialog to create new channel
│   ├── bridge_text_chat.dart             # Chat message list + input
│   ├── bridge_voice_strip.dart           # Horizontal voice participant strip
│   ├── bridge_voice_controls.dart        # Bottom bar: mic, deafen, disconnect
│   ├── bridge_chat_message_bubble.dart   # Individual message widget
│   └── widgets/
│       ├── bridge_member_list.dart       # Right sidebar: who's in channel
│       └── bridge_server_icon.dart       # Server icon with notification dot
│
└── providers/
    └── bridge_state_provider.dart        # Riverpod providers for global bridge state
```

---

## UI Layout (Discord-Style)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Server Rail │  Channel List     │  Voice Channel View                      │
│              │                   │                                          │
│  ┌────────┐  │  ┌─────────────┐  │  ┌──────────────────────────────────┐   │
│  │  🏥    │  │  VOICE CHANNELS│  │  │  # general                        │   │
│  │ City   │◄─┤                │  │  │  ─────────────────────────────────│   │
│  │ General│  │  # general     │  │  │                                  │   │
│  │        │  │  # emergency   │  │  │  ┌─ Voice Participant Strip ────┐│   │
│  ├────────┤  │  # bed-coord   │  │  │  │  👤 Dr.Smith  👤 Nurse.Jane  ││   │
│  │  🏥    │  │  # admin       │  │  │  │   🟢 speaking   🔇 muted     ││   │
│  │ Metro  │  │                │  │  │  └──────────────────────────────┘│   │
│  │        │  │  ───────────── │  │  │                                  │   │
│  ├────────┤  │  + Create      │  │  │  ┌─ Text Chat ──────────────────┐│   │
│  │  ⚡    │  │    Channel     │  │  │  │ Dr.Smith: Bed 4 available    ││   │
│  │ Master │  │                │  │  │  │ Nurse.Jane: Copy that        ││   │
│  │ Command│  │  ───────────── │  │  │  │ You: On my way               ││   │
│  │        │  │  ONLINE: 12    │  │  │  └──────────────────────────────┘│   │
│  └────────┘  └─────────────────┘  │  └──────────────────────────────────┘   │
│              │                   │  ┌──────────────────────────────────┐   │
│              │                   │  │  🎤  🔇  🎧  📞 Leave            │   │
│              │                   │  │  Mic  Mute Deafen Disconnect     │   │
│              │                   │  └──────────────────────────────────┘   │
│              │                   │                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Voice Controls (Bottom Bar)

| Control | Icon | Action |
|---------|------|--------|
| **Mic Toggle** | `mic` / `mic_off` | Enable/disable local microphone publishing |
| **Mute** (same as mic toggle) | `mic_off` | Toggle microphone — red when muted |
| **Deafen** | `headset` / `headset_off` | Mute all incoming audio from remote participants |
| **Disconnect** | `call_end` | Leave the voice channel (red button) |

### Speaking Indicators

- **Green ring** around avatar = currently speaking (from LiveKit `ActiveSpeakersChangedEvent`)
- **Red mic icon overlay** = microphone muted
- **Gray avatar** = deafened user (can't hear others)

---

## Voice State Model

```dart
enum BridgeMicState { on, muted }
enum BridgeHearState { hearing, deafened }

class BridgeVoiceState {
  final BridgeMicState mic;
  final BridgeHearState hearing;
  final bool isSpeaking;        // from LiveKit VAD
  final String participantId;
  final String displayName;
  final bool isLocal;
}
```

### Deafen Implementation

When deafened:
1. Iterate all `RemoteParticipant` tracks in the room
2. Call `track.mute()` on every remote audio track
3. On undeafen, call `track.unmute()`
4. UI shows `headset_off` icon with red tint

### Mic Mute Implementation

```dart
await room.localParticipant?.setMicrophoneEnabled(false);  // mute
await room.localParticipant?.setMicrophoneEnabled(true);   // unmute
```

---

## Text Chat via LiveKit Data Channels

### Message Format

```json
{
  "type": "bridge_chat",
  "userId": "firebase_uid",
  "displayName": "Dr. Smith",
  "hospitalId": "hosp_abc123",
  "content": "Bed 4 available in ER",
  "timestamp": 1712345678000,
  "messageId": "uuid_v4"
}
```

### Publishing

```dart
final payload = jsonEncode(messageMap);
await room.localParticipant!.publishData(
  utf8.encode(payload),
  reliable: true,
  topic: 'bridge_chat',
);
```

### Listening

```dart
listener.on<DataReceivedEvent>((e) {
  if (e.topic != 'bridge_chat') return;
  final msg = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>;
  // Add to chat message list
});
```

---

## Riverpod State Providers

```dart
// Currently selected server
final selectedServerProvider = StateProvider<BridgeServer?>((ref) => null);

// Currently selected channel
final selectedChannelProvider = StateProvider<BridgeChannel?>((ref) => null);

// Active LiveKit room (null when not in a voice channel)
final bridgeRoomProvider = StateProvider<Room?>((ref) => null);

// Voice states of all participants in current room
final bridgeVoiceStatesProvider = StateProvider<List<BridgeVoiceState>>((ref) => []);

// Chat messages in current channel
final bridgeChatMessagesProvider = StateProvider<List<BridgeChatMessage>>((ref) => []);

// Local user's voice state
final bridgeLocalVoiceStateProvider = StateProvider<BridgeVoiceState>((ref) =>
  BridgeVoiceState(mic: BridgeMicState.on, hearing: BridgeHearState.hearing, ...)
);

// Server list (from Firestore)
final bridgeServersProvider = StreamProvider<List<BridgeServer>>((ref) => ...);

// Channels for selected server (from Firestore)
final bridgeChannelsProvider = StreamProvider.family<List<BridgeChannel>, String>((ref, serverId) => ...);
```

---

## Navigation Integration

The Hospital Bridge will be accessible from:

1. **Hospital Dashboard** — "Bridge" button in the dashboard screen
2. **Master Admin Command Center** — "Hospital Bridge" tab
3. **Global Navigation** — Bottom nav bar icon (optional, based on user role)

Route: `/hospital-bridge`

---

## Permissions & Access Control

| Role | Can Join | Can Create Channels | Can Delete Channels | Can Moderate |
|------|----------|---------------------|---------------------|--------------|
| **Hospital Admin** | Own hospital server + Master server | Own hospital server | Own hospital server | Own hospital server |
| **Master Admin** | All servers | All servers | All servers | All servers |

Firestore security rules will enforce:
- Only authenticated users can read servers they're members of
- Channel creation requires `bridge_servers/{serverId}.admins` array contains `request.auth.uid`
- Channel deletion requires same admin check

---

## Audio Assets

Existing assets will be reused:
- `assets/sounds/livekit_join.wav` — play when participant joins
- `assets/sounds/livekit_leave.wav` — play when participant leaves

New asset (optional):
- `assets/sounds/bridge_message.wav` — notification sound for new chat message

---

## Implementation Phases

### Phase 1: Core Infrastructure
1. Firestore collections + security rules
2. Cloud Functions (token, create/delete/list channels)
3. `HospitalBridgeService` — connect/disconnect, mic/deafen toggles
4. Domain models (`BridgeServer`, `BridgeChannel`, `BridgeChatMessage`)

### Phase 2: Discord-Style UI
1. Server rail (left sidebar)
2. Channel list (middle sidebar)
3. Channel screen with voice strip + text chat
4. Bottom voice controls (mic, deafen, disconnect)

### Phase 3: Real-Time Features
1. Active speaker detection with green ring animation
2. Join/leave sounds
3. Chat message publishing and receiving via data channels
4. Participant list sidebar

### Phase 4: Polish
1. Channel creation dialog
2. Channel rename/delete (admin only)
3. Notification dots for unread messages
4. Online member count in sidebar
5. Responsive layout for mobile/tablet/desktop

---

## Key Design Decisions

1. **LiveKit data channels for chat** — Ephemeral, real-time, tied to voice room lifecycle. Matches Discord's model where chat is room-scoped. No persistence — messages are lost when room empties.

2. **One LiveKit room per channel** — Each voice channel is a separate LiveKit room. Users can only be in one channel at a time (like Discord).

3. **Firestore for channel metadata only** — Server/channel definitions, memberships, and permissions live in Firestore. Voice and chat data flow through LiveKit.

4. **Riverpod for state** — Consistent with existing EmergencyOS patterns. `ChangeNotifierProvider` for the bridge service, `StateProvider` for UI state, `StreamProvider` for Firestore streams.

5. **Dark theme only** — Matches Discord's dark aesthetic and existing EmergencyOS dark theme (`Color(0xFF0D1117)` background, `Color(0xFF161B22)` surfaces).
