const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { AccessToken, AgentDispatchClient, RoomServiceClient } = require("livekit-server-sdk");

const lkSecret = defineSecret("LIVEKIT_API_SECRET");

function liveKitEnv(secretFromBinding) {
  const url = (process.env.LIVEKIT_URL || "").trim();
  const apiKey = (process.env.LIVEKIT_API_KEY || "").trim();
  const apiSecret = (process.env.LIVEKIT_API_SECRET || (secretFromBinding || "") || "").toString().trim();
  return { url, apiKey, apiSecret };
}

function assertLiveKitConfigured(env) {
  if (!env.url || !env.apiKey || !env.apiSecret) {
    throw new HttpsError(
      "failed-precondition",
      "LiveKit not configured. Local: copy functions/.env.example to functions/.env. Production: firebase functions:secrets:set LIVEKIT_API_SECRET; set LIVEKIT_URL and LIVEKIT_API_KEY."
    );
  }
}

function generateToken(roomName, identity, metadata, canPublishAudio, canSubscribe, muteOnConnect) {
  const env = liveKitEnv();
  assertLiveKitConfigured(env);
  const at = new AccessToken(env.apiKey, env.apiSecret, {
    identity,
    metadata: metadata || "",
    ttl: "24h",
  });
  at.addGrant({
    room: roomName,
    roomJoin: true,
    canPublish: true,
    canSubscribe: true,
    canPublishData: true,
  });
  return at.toJwt();
}

exports.getLivekitToken = onCall({ secrets: [lkSecret] }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const { roomName, identity, metadata, canPublishAudio, canSubscribe, muteOnConnect } = request.data;
  if (!roomName || !identity) throw new HttpsError("invalid-argument", "roomName and identity required");
  const token = generateToken(roomName, identity, metadata, canPublishAudio, canSubscribe, muteOnConnect);
  return { token, url: liveKitEnv().url };
});

exports.getOperationsLivekitToken = onCall({ secrets: [lkSecret] }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const { roomName } = request.data;
  if (!roomName) throw new HttpsError("invalid-argument", "roomName required");
  const uid = request.auth.uid;
  const identity = `ops_${uid}`;
  const token = generateToken(roomName, identity, JSON.stringify({ role: "operator" }), true, true, false);
  return { token, url: liveKitEnv().url };
});

exports.getAdminConsoleLivekitToken = onCall({ secrets: [lkSecret] }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const { roomName } = request.data;
  if (!roomName) throw new HttpsError("invalid-argument", "roomName required");
  const uid = request.auth.uid;
  const identity = `admin_${uid}`;
  const token = generateToken(roomName, identity, JSON.stringify({ role: "admin" }), true, true, false);
  return { token, url: liveKitEnv().url };
});

exports.ensureEmergencyBridge = onCall({ secrets: [lkSecret] }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const { incidentId } = request.data;
  if (!incidentId) throw new HttpsError("invalid-argument", "incidentId required");
  const env = liveKitEnv();
  assertLiveKitConfigured(env);
  const roomName = `sos_${incidentId}`;
  const dispatch = new AgentDispatchClient(env.url, env.apiKey, env.apiSecret);
  const roomClient = new RoomServiceClient(env.url, env.apiKey, env.apiSecret);
  const rooms = await roomClient.listRooms([roomName]);
  if (rooms.length === 0) {
    await roomClient.createRoom({ name: roomName, emptyTimeout: 600, maxParticipants: 50 });
  }
  const lifelineAgentName = process.env.LIFELINE_LIVEKIT_AGENT_NAME || process.env.LIVEKIT_AGENT_NAME || "lifeline";
  try {
    await dispatch.createDispatch(roomName, { agentName: lifelineAgentName, metadata: JSON.stringify({ incidentId, variant: "sos" }) });
  } catch (e) {
    console.warn("Lifeline agent dispatch failed:", e);
  }
  return { roomName, url: env.url };
});

exports.dispatchLifelineComms = onCall({ secrets: [lkSecret] }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const { incidentId, text } = request.data;
  if (!incidentId || !text) throw new HttpsError("invalid-argument", "incidentId and text required");
  const env = liveKitEnv();
  assertLiveKitConfigured(env);
  const roomName = `sos_${incidentId}`;
  const dispatch = new AgentDispatchClient(env.url, env.apiKey, env.apiSecret);
  try {
    await dispatch.createDispatch(roomName, { agentName: "lifeline", metadata: JSON.stringify({ incidentId, text, action: "speak" }) });
  } catch (e) {
    console.warn("Lifeline comms dispatch failed:", e);
  }
  return { ok: true };
});

exports.getCopilotLivekitToken = onCall({ secrets: [lkSecret] }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const uid = request.auth.uid;
  const roomName = `copilot_${uid}`;
  const identity = `user_${uid}`;
  const token = generateToken(roomName, identity, JSON.stringify({ role: "user" }), true, true, false);
  return { token, url: liveKitEnv().url, roomName };
});

exports.ensureCopilotAgent = onCall({ secrets: [lkSecret] }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const uid = request.auth.uid;
  const roomName = `copilot_${uid}`;
  const env = liveKitEnv();
  assertLiveKitConfigured(env);
  const dispatch = new AgentDispatchClient(env.url, env.apiKey, env.apiSecret);
  const roomClient = new RoomServiceClient(env.url, env.apiKey, env.apiSecret);
  const rooms = await roomClient.listRooms([roomName]);
  if (rooms.length === 0) {
    await roomClient.createRoom({ name: roomName, emptyTimeout: 300, maxParticipants: 10 });
  }
  try {
    await dispatch.createDispatch(roomName, { agentName: "copilot", metadata: JSON.stringify({ uid }) });
  } catch (e) {
    console.warn("Copilot agent dispatch failed:", e);
  }
  return { roomName, url: env.url };
});

exports.getOpsSystemHealth = onCall({ secrets: [lkSecret] }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const admin = require("firebase-admin");
  const db = admin.firestore();
  const checkedAt = Date.now();
  let gcpOk = true;
  let gcpDetail = "Firestore query OK";
  try {
    await db.collection("_health_check").limit(1).get();
  } catch (e) {
    gcpOk = false;
    gcpDetail = String(e?.message || e);
  }
  let livekitOk = false;
  let livekitDetail = "Not configured";
  try {
    const env = liveKitEnv();
    if (env.url && env.apiKey && env.apiSecret) {
      const roomClient = new RoomServiceClient(env.url, env.apiKey, env.apiSecret);
      const rooms = await roomClient.listRooms();
      livekitOk = true;
      livekitDetail = `${rooms.length} room(s) listed`;
    }
  } catch (e) {
    livekitOk = false;
    livekitDetail = String(e?.message || e);
  }
  const twilioSid = process.env.TWILIO_ACCOUNT_SID;
  const twilioToken = process.env.TWILIO_AUTH_TOKEN;
  const twilioNumber = (process.env.TWILIO_PHONE_NUMBER || "").trim();
  const smsOk = !!(twilioSid && twilioToken && twilioNumber);
  const smsDetail = smsOk
    ? "Twilio env vars present"
    : "Twilio not fully configured (SID, token, or TWILIO_PHONE_NUMBER)";
  const ok = gcpOk && livekitOk && smsOk;
  const summary = ok
    ? "All integration checks passed"
    : "One or more integration checks reported issues";
  return {
    ok,
    summary,
    checkedAt,
    services: {
      gcp: { ok: gcpOk, label: "GCP / Firestore", detail: gcpDetail },
      livekit: { ok: livekitOk, label: "LiveKit", detail: livekitDetail },
      sms: { ok: smsOk, label: "SMS (Twilio)", detail: smsDetail },
    },
  };
});

exports.getOpsDataPlaneHealth = onCall({ secrets: [lkSecret] }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const admin = require("firebase-admin");
  const db = admin.firestore();
  const activeIncidents = await db.collection("sos_incidents").where("status", "in", ["pending", "dispatched", "accepted"]).count().get();
  return { activeIncidents: activeIncidents.data().count, timestamp: Date.now() };
});
