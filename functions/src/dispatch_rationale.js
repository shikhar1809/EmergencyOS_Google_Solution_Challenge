// Gemini-powered short rationale explaining *why* a specific hospital
// topped the dispatch chain for an incident. This is meant to be shown on
// the ops dashboard and the victim's hospital card so responders (and judges)
// can see the AI's reasoning in plain language.
//
// Non-critical: all failures are swallowed. The dispatch decision itself is
// always made by the deterministic scoring engine in hospital_dispatch_v2.js;
// this module only annotates it.

const admin = require("firebase-admin");
const { GoogleGenAI } = require("@google/genai");
const { withSafetyForRole } = require("./ai_safety");

const db = admin.firestore();
const { FieldValue } = admin.firestore;

function getGeminiKey() {
  try {
    return process.env.GEMINI_API_KEY || "";
  } catch (_) {
    return "";
  }
}

function buildDispatchContext(incident, assignment) {
  const inc = incident || {};
  const asg = assignment || {};
  const ranked = Array.isArray(asg.rankedCandidates) ? asg.rankedCandidates.slice(0, 3) : [];

  const lines = [];
  lines.push(`INCIDENT_ID=${asg.incidentId || inc.id || "?"}`);
  lines.push(`TYPE=${inc.type || ""}`);
  lines.push(`SEVERITY_TIER=${asg.severityTier || ""}`);
  lines.push(`REQUIRED_SERVICES=${Array.isArray(asg.requiredServices) ? asg.requiredServices.join(",") : ""}`);

  const aiVision = inc.triage && inc.triage.aiVision;
  if (aiVision && typeof aiVision === "object") {
    lines.push(`AI_TRIAGE_SEVERITY=${aiVision.severity || ""}`);
    lines.push(`AI_TRIAGE_CATEGORY=${aiVision.category || ""}`);
    lines.push(`AI_RECOMMENDED_SPECIALTY=${aiVision.aiRecommendedSpecialty || ""}`);
  }

  if (asg.notifiedHospitalName) {
    lines.push(`CHOSEN_HOSPITAL=${asg.notifiedHospitalName}`);
  }

  ranked.forEach((c, i) => {
    const parts = [
      `rank=${c.rank || i + 1}`,
      `name=${c.name || c.id}`,
      `score=${c.score}`,
      `distKm=${c.distKm}`,
      `etaSec=${c.etaSec}`,
      `bedsAvailable=${c.bedsAvailable}`,
      `offered=${Array.isArray(c.offeredServices) ? c.offeredServices.slice(0, 6).join("|") : ""}`,
    ];
    lines.push(`CANDIDATE_${i + 1}=${parts.join("; ")}`);
  });

  return lines.join("\n");
}

/**
 * Writes a short AI rationale onto the ops assignment doc AND mirrors
 * summary fields onto the incident doc so the victim's app can show it too.
 *
 * Returns `{ ok, rationale?, error? }`.
 */
async function writeAiHospitalRationale({ incidentId, incident, assignment }) {
  if (!incidentId) return { ok: false, error: "no_incidentId" };
  if (!getGeminiKey()) return { ok: false, error: "no_gemini_key" };

  const ctx = buildDispatchContext(incident, assignment);
  const prompt = withSafetyForRole(
    "brief",
    "You are explaining a hospital dispatch decision to a dispatcher and the victim's family. " +
    "Using ONLY the structured DISPATCH_CONTEXT below, write a short plain-English rationale (max 3 sentences, ~50 words) " +
    "for why the chosen hospital is the right match. Mention 1–2 concrete factors (e.g. specialty match, distance/ETA, bed availability, AI triage). " +
    "Do not invent facts. Do not list all candidates. Do not use markdown or JSON.\n\n" +
    `## DISPATCH_CONTEXT\n${ctx}\n\nRationale:`
  );

  try {
    const ai = new GoogleGenAI({ apiKey: getGeminiKey() });
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: [prompt],
      generationConfig: { temperature: 0.25, maxOutputTokens: 220 },
    });
    const text = typeof response?.text === "function" ? response.text() : "";
    const rationale = (text || "").toString().trim();
    if (!rationale) return { ok: false, error: "empty_response" };

    const aiHospitalRationale = {
      text: rationale.length > 600 ? `${rationale.slice(0, 600)}…` : rationale,
      hospitalId: assignment?.notifiedHospitalId || null,
      hospitalName: assignment?.notifiedHospitalName || null,
      severityTier: assignment?.severityTier || null,
      generatedBy: "gemini-2.5-flash",
      generatedAt: FieldValue.serverTimestamp(),
    };

    await Promise.all([
      db
        .collection("ops_incident_hospital_assignments")
        .doc(incidentId)
        .set({ aiHospitalRationale }, { merge: true }),
      db
        .collection("sos_incidents")
        .doc(incidentId)
        .set({ aiHospitalRationale }, { merge: true }),
    ]);

    return { ok: true, rationale: aiHospitalRationale.text };
  } catch (e) {
    console.warn("[dispatch_rationale] generation failed:", e && e.message);
    return { ok: false, error: String(e && e.message || e) };
  }
}

module.exports = { writeAiHospitalRationale };
