// Gemini-generated pre-arrival handoff packet.
//
// When an ambulance's ETA to the receiving hospital drops below ~2 minutes,
// this module asks Gemini to produce a structured handoff bundle that the
// receiving hospital sees on their dashboard the moment the ambulance pulls
// in. The goal is to buy the trauma team those last 90 seconds so the bay,
// blood units, OR, and specialist are ready before the patient rolls through
// the door.
//
// Dispatch decisions NEVER depend on this module — it only annotates.

const admin = require("firebase-admin");
const { GoogleGenAI } = require("@google/genai");
const { withSafetyForRole } = require("./ai_safety");

const db = admin.firestore();
const { FieldValue } = admin.firestore;

const HANDOFF_ETA_THRESHOLD_SEC = 120; // 2 minutes

function getGeminiKey() {
  try {
    return process.env.GEMINI_API_KEY || "";
  } catch (_) {
    return "";
  }
}

/** Parse "~5 min", "3m", "180s", "180" into seconds. Returns null if unknown. */
function parseEtaToSeconds(raw) {
  if (raw == null) return null;
  if (typeof raw === "number" && isFinite(raw)) return Math.round(raw);
  const s = String(raw).trim().toLowerCase();
  if (!s) return null;
  const mMin = s.match(/(-?\d+(?:\.\d+)?)\s*(m|min|mins|minute|minutes)\b/);
  if (mMin) return Math.round(parseFloat(mMin[1]) * 60);
  const mSec = s.match(/(-?\d+(?:\.\d+)?)\s*(s|sec|secs|second|seconds)\b/);
  if (mSec) return Math.round(parseFloat(mSec[1]));
  const bare = s.match(/(-?\d+(?:\.\d+)?)/);
  if (bare) {
    const n = parseFloat(bare[1]);
    if (!isFinite(n)) return null;
    return n > 60 ? Math.round(n) : Math.round(n * 60);
  }
  return null;
}

function shouldGenerate(after, before) {
  if (!after || typeof after !== "object") return false;
  if (after.preArrivalHandoff && after.preArrivalHandoff.status === "ready") return false;

  const afterSec = parseEtaToSeconds(after.ambulanceEta);
  if (afterSec == null) return false;
  if (afterSec > HANDOFF_ETA_THRESHOLD_SEC) return false;
  if (afterSec < 0) return false;

  const beforeSec = parseEtaToSeconds(before && before.ambulanceEta);
  if (beforeSec != null && beforeSec <= HANDOFF_ETA_THRESHOLD_SEC) {
    // Already crossed the threshold on a previous update; only (re)generate
    // if we don't have a handoff at all or it errored out.
    const ph = after.preArrivalHandoff;
    if (ph && ph.status === "ready") return false;
    if (ph && ph.status === "generating") return false;
  }

  const phase = String(after.emsWorkflowPhase || "").toLowerCase();
  if (phase === "response_complete" || phase === "hospital_arrival") return false;

  return true;
}

function buildDigest(incidentId, inc) {
  const lines = [];
  lines.push(`INCIDENT_ID=${incidentId}`);
  lines.push(`TYPE=${inc.type || ""}`);
  lines.push(`SEVERITY_TIER=${inc.severityTier || ""}`);
  lines.push(`AMBULANCE_ETA=${inc.ambulanceEta || ""}`);
  if (inc.userDisplayName) lines.push(`PATIENT_NAME=${String(inc.userDisplayName).slice(0, 80)}`);
  if (inc.bloodType) lines.push(`BLOOD_TYPE=${inc.bloodType}`);
  if (inc.allergies) lines.push(`ALLERGIES=${String(inc.allergies).slice(0, 250)}`);
  if (inc.medicalConditions) lines.push(`CONDITIONS=${String(inc.medicalConditions).slice(0, 300)}`);
  if (inc.medicalStatus) lines.push(`MEDICAL_STATUS=${inc.medicalStatus}`);
  if (inc.emsWorkflowPhase) lines.push(`EMS_PHASE=${inc.emsWorkflowPhase}`);

  const aiVision = inc.triage && inc.triage.aiVision;
  if (aiVision && typeof aiVision === "object") {
    lines.push(`AI_TRIAGE_SEVERITY=${aiVision.severity || ""}`);
    lines.push(`AI_TRIAGE_CATEGORY=${aiVision.category || ""}`);
    lines.push(`AI_RECOMMENDED_SPECIALTY=${aiVision.aiRecommendedSpecialty || ""}`);
    if (aiVision.analysis) lines.push(`AI_TRIAGE_ANALYSIS=${String(aiVision.analysis).slice(0, 500)}`);
  }

  const brief = inc.sharedSituationBrief;
  if (brief && typeof brief === "object" && brief.summary) {
    lines.push(`SITUATION_BRIEF=${String(brief.summary).slice(0, 600)}`);
  }

  const rationale = inc.aiHospitalRationale;
  if (rationale && typeof rationale === "object") {
    if (rationale.hospitalName) lines.push(`RECEIVING_HOSPITAL=${rationale.hospitalName}`);
    if (rationale.text) lines.push(`DISPATCH_RATIONALE=${String(rationale.text).slice(0, 300)}`);
  }

  return lines.join("\n");
}

/**
 * Fire-and-forget: generate + persist a pre-arrival handoff packet.
 * Always resolves; never throws.
 */
async function maybeGeneratePreArrivalHandoff(incidentId, after, before) {
  if (!incidentId) return { ok: false, reason: "no_incidentId" };
  if (!shouldGenerate(after, before)) return { ok: false, reason: "not_eligible" };
  if (!getGeminiKey()) return { ok: false, reason: "no_gemini_key" };

  const ref = db.collection("sos_incidents").doc(incidentId);

  try {
    await ref.set({
      preArrivalHandoff: {
        status: "generating",
        startedAt: FieldValue.serverTimestamp(),
      },
    }, { merge: true });
  } catch (e) {
    console.warn("[preArrivalHandoff] pre-write failed:", e && e.message);
  }

  const digest = buildDigest(incidentId, after || {});
  const prompt = withSafetyForRole(
    "brief",
    "The ambulance for this incident is ~2 minutes from the receiving hospital. Produce a concise PRE-ARRIVAL HANDOFF packet " +
    "for the trauma team. Use ONLY the structured EVIDENCE below. Do not invent vitals or medications. " +
    "Output ONLY JSON matching the schema.\n\n" +
    `## EVIDENCE\n${digest}`
  );

  const schema = {
    type: "object",
    properties: {
      patientSnapshot: { type: "string", description: "1-2 sentences: age/sex if known, chief complaint, vitals summary." },
      likelyPresentation: { type: "string", description: "1 sentence: what the trauma team should expect." },
      prepareRoom: {
        type: "array",
        items: { type: "string" },
        description: "Actionable bay/room prep items (e.g. 'Activate cardiac cath lab', 'Prep trauma bay 2', 'Open airway cart').",
      },
      prepareTeam: {
        type: "array",
        items: { type: "string" },
        description: "On-call specialists / roles to page (e.g. 'Cardiology on-call', 'Orthopedics trauma', 'OB/GYN').",
      },
      bloodAndMeds: {
        type: "array",
        items: { type: "string" },
        description: "Blood units, type-and-crossmatch, tranexamic acid, etc. Keep short and safe.",
      },
      contraindications: {
        type: "array",
        items: { type: "string" },
        description: "Known allergies / conditions from the patient profile to avoid.",
      },
      etaSeconds: { type: "integer", description: "Echo of parsed ETA in seconds." },
    },
    required: ["patientSnapshot", "likelyPresentation", "prepareRoom", "prepareTeam"],
  };

  let parsed = null;
  try {
    const ai = new GoogleGenAI({ apiKey: getGeminiKey() });
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: [prompt],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 700,
        responseMimeType: "application/json",
        responseSchema: schema,
      },
    });
    const text = typeof response?.text === "function" ? response.text() : "";
    parsed = text ? JSON.parse(text) : null;
  } catch (e) {
    console.warn("[preArrivalHandoff] Gemini call failed:", e && e.message);
    try {
      await ref.set({
        preArrivalHandoff: {
          status: "error",
          lastError: String((e && e.message) || e).slice(0, 280),
          completedAt: FieldValue.serverTimestamp(),
        },
      }, { merge: true });
    } catch (_) {}
    return { ok: false, reason: "gemini_failed" };
  }

  if (!parsed || typeof parsed !== "object") {
    return { ok: false, reason: "empty" };
  }

  const etaSec = parseEtaToSeconds(after && after.ambulanceEta) || 0;

  const packet = {
    status: "ready",
    patientSnapshot: String(parsed.patientSnapshot || "").slice(0, 800),
    likelyPresentation: String(parsed.likelyPresentation || "").slice(0, 400),
    prepareRoom: Array.isArray(parsed.prepareRoom) ? parsed.prepareRoom.map((x) => String(x)).filter(Boolean).slice(0, 8) : [],
    prepareTeam: Array.isArray(parsed.prepareTeam) ? parsed.prepareTeam.map((x) => String(x)).filter(Boolean).slice(0, 8) : [],
    bloodAndMeds: Array.isArray(parsed.bloodAndMeds) ? parsed.bloodAndMeds.map((x) => String(x)).filter(Boolean).slice(0, 8) : [],
    contraindications: Array.isArray(parsed.contraindications) ? parsed.contraindications.map((x) => String(x)).filter(Boolean).slice(0, 8) : [],
    etaSeconds: etaSec,
    hospitalId: (after && after.aiHospitalRationale && after.aiHospitalRationale.hospitalId) || null,
    hospitalName: (after && after.aiHospitalRationale && after.aiHospitalRationale.hospitalName) || null,
    generatedBy: "gemini-2.5-flash",
    generatedAt: FieldValue.serverTimestamp(),
  };

  try {
    await ref.set({ preArrivalHandoff: packet }, { merge: true });
    return { ok: true };
  } catch (e) {
    console.warn("[preArrivalHandoff] persist failed:", e && e.message);
    return { ok: false, reason: "persist_failed" };
  }
}

module.exports = { maybeGeneratePreArrivalHandoff, parseEtaToSeconds, HANDOFF_ETA_THRESHOLD_SEC };
