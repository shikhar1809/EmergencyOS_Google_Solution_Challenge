// Gemini clinical synthesis for ED handover reports (read-only; caller persists).
// Does not write Firestore. Always resolves — never throws to the client.

const admin = require("firebase-admin");
const { GoogleGenAI } = require("@google/genai");
const { withSafetyForRole } = require("./ai_safety");

const db = admin.firestore();

function geminiKey() {
  try {
    return (process.env.GEMINI_API_KEY || "").trim();
  } catch (_) {
    return "";
  }
}

function sanitizeUserField(value, maxLen) {
  if (!value || typeof value !== "string") return "";
  let s = value
    .replace(/ignore\s+(previous|above|all)\s+instructions?/gi, "[redacted]")
    .replace(/\bsystem\b[\s\S]{0,40}\bprompt\b/gi, "[redacted]")
    .replace(/\byou are now\b/gi, "[redacted]")
    .replace(/\bforget everything\b/gi, "[redacted]")
    .replace(/\bact as\b/gi, "[redacted]")
    .replace(/[\r\n]+/g, " ")
    .trim();
  return s.slice(0, maxLen || 500);
}

function isoMaybe(v) {
  if (!v) return "";
  try {
    if (v.toDate) return v.toDate().toISOString();
    if (typeof v === "string") return v;
  } catch (_) {}
  return String(v);
}

function buildFleetHandoffLines(handoffSnaps) {
  const lines = [];
  if (!Array.isArray(handoffSnaps) || handoffSnaps.length === 0) {
    lines.push("FLEET_OPERATOR_HANDOFF=none");
    return lines;
  }
  handoffSnaps.forEach((doc, i) => {
    const d = doc.data() || {};
    const notes = sanitizeUserField(String(d.notesText || ""), 6000);
    const urls = Array.isArray(d.photoUrls) ? d.photoUrls.filter((u) => typeof u === "string" && u.trim()) : [];
    lines.push(`FLEET_HANDOFF_${i + 1}_OPERATOR=${String(d.operatorUid || doc.id || "").slice(0, 64)}`);
    lines.push(`FLEET_HANDOFF_${i + 1}_NOTES=${notes}`);
    lines.push(`FLEET_HANDOFF_${i + 1}_PHOTO_COUNT=${urls.length}`);
  });
  return lines;
}

function buildClinicalDigest(incidentId, inc, handoffDocs) {
  const lines = [];
  lines.push(`INCIDENT_ID=${incidentId}`);
  lines.push(`TYPE=${inc.type || ""}`);
  lines.push(`STATUS=${inc.status || ""}`);
  lines.push(`SEVERITY_TIER=${inc.severityTier || ""}`);
  lines.push(`VICTIM=${sanitizeUserField(String(inc.userDisplayName || ""), 80)}`);
  lines.push(`USER_ID=${String(inc.userId || "").slice(0, 64)}`);
  lines.push(`LAT_LNG=${inc.lat},${inc.lng}`);
  lines.push(`SOS_AT=${isoMaybe(inc.timestamp)}`);
  lines.push(`FIRST_ACK_AT=${isoMaybe(inc.firstAcknowledgedAt)}`);
  lines.push(`EMS_ACCEPTED_AT=${isoMaybe(inc.emsAcceptedAt)}`);
  lines.push(`EMS_ON_SCENE_AT=${isoMaybe(inc.emsOnSceneAt)}`);
  lines.push(`EMS_RESCUE_COMPLETE_AT=${isoMaybe(inc.emsRescueCompleteAt)}`);
  lines.push(`EMS_RETURNING_AT=${isoMaybe(inc.emsReturningStartedAt)}`);
  lines.push(`EMS_HOSPITAL_ARRIVAL_AT=${isoMaybe(inc.emsHospitalArrivalAt)}`);
  lines.push(`EMS_RESPONSE_COMPLETE_AT=${isoMaybe(inc.emsResponseCompleteAt)}`);
  lines.push(`EMS_PHASE=${inc.emsWorkflowPhase || ""}`);
  lines.push(`AMBULANCE_ETA=${inc.ambulanceEta || ""}`);
  lines.push(`MEDICAL_STATUS=${sanitizeUserField(String(inc.medicalStatus || ""), 500)}`);
  if (inc.bloodType) lines.push(`BLOOD_TYPE=${sanitizeUserField(inc.bloodType, 20)}`);
  if (inc.allergies) lines.push(`ALLERGIES=${sanitizeUserField(inc.allergies, 250)}`);
  if (inc.medicalConditions) lines.push(`CONDITIONS=${sanitizeUserField(inc.medicalConditions, 300)}`);

  const brief = inc.sharedSituationBrief && typeof inc.sharedSituationBrief === "object" ? inc.sharedSituationBrief : {};
  if (brief.summary) lines.push(`SITUATION_BRIEF_SUMMARY=${sanitizeUserField(String(brief.summary), 1200)}`);

  const ph = inc.preArrivalHandoff && typeof inc.preArrivalHandoff === "object" ? inc.preArrivalHandoff : {};
  if (ph.patientSnapshot) lines.push(`PRE_ARRIVAL_PATIENT_SNAPSHOT=${sanitizeUserField(String(ph.patientSnapshot), 800)}`);
  if (ph.likelyPresentation) lines.push(`PRE_ARRIVAL_LIKELY=${sanitizeUserField(String(ph.likelyPresentation), 400)}`);
  if (Array.isArray(ph.prepareRoom)) lines.push(`PRE_ARRIVAL_PREPARE_ROOM=${JSON.stringify(ph.prepareRoom).slice(0, 800)}`);
  if (Array.isArray(ph.prepareTeam)) lines.push(`PRE_ARRIVAL_PREPARE_TEAM=${JSON.stringify(ph.prepareTeam).slice(0, 800)}`);

  if (inc.triage && typeof inc.triage === "object") {
    lines.push(`TRIAGE_JSON=${JSON.stringify(inc.triage).slice(0, 6000)}`);
  }
  if (inc.volunteerSceneReport && typeof inc.volunteerSceneReport === "object") {
    lines.push(`VOLUNTEER_SCENE_JSON=${JSON.stringify(inc.volunteerSceneReport).slice(0, 12000)}`);
  }
  if (inc.videoAssessment && typeof inc.videoAssessment === "object") {
    lines.push(`VIDEO_ASSESSMENT_JSON=${JSON.stringify(inc.videoAssessment).slice(0, 8000)}`);
  }
  if (inc.aiHospitalRationale && typeof inc.aiHospitalRationale === "object") {
    lines.push(`HOSPITAL_RATIONALE_JSON=${JSON.stringify(inc.aiHospitalRationale).slice(0, 2000)}`);
  }
  if (inc.adminDispatchNote) lines.push(`DISPATCH_NOTE=${sanitizeUserField(inc.adminDispatchNote, 2000)}`);

  lines.push(...buildFleetHandoffLines(handoffDocs));

  return lines.join("\n");
}

/**
 * @param {string} incidentId
 * @returns {Promise<{ ok: boolean, error?: string, clinicalSynthesis?: string, redFlags?: string[], expectedInterventions?: string[], handoverScript?: string }>}
 */
async function generateClinicalReportCore(incidentId) {
  const id = (incidentId || "").toString().trim();
  if (!id) {
    return { ok: false, error: "no_incidentId" };
  }

  try {
    const ref = db.collection("sos_incidents").doc(id);
    const snap = await ref.get();
    if (!snap.exists) {
      return { ok: false, error: "not_found" };
    }
    const inc = snap.data() || {};

    let handoffDocs = [];
    try {
      const sub = await ref.collection("fleet_operator_handoff").limit(16).get();
      handoffDocs = sub.docs.slice().sort((a, b) => {
        const ta = (a.data() && a.data().updatedAt && a.data().updatedAt.toMillis)
          ? a.data().updatedAt.toMillis() : 0;
        const tb = (b.data() && b.data().updatedAt && b.data().updatedAt.toMillis)
          ? b.data().updatedAt.toMillis() : 0;
        return tb - ta;
      }).slice(0, 8);
    } catch (e) {
      console.warn("[clinicalReport] fleet_operator_handoff read failed:", e && e.message);
      handoffDocs = [];
    }

    const k = geminiKey();
    if (!k) {
      return {
        ok: false,
        error: "no_api_key",
        clinicalSynthesis: "",
        redFlags: [],
        expectedInterventions: [],
        handoverScript: "",
      };
    }

    const digest = buildClinicalDigest(id, inc, handoffDocs);
    const prompt = withSafetyForRole(
      "brief",
      "You are assisting emergency department clinicians with a PRE-HOSPITAL HANDOVER summary. " +
        "Use ONLY the structured EVIDENCE below. Do not diagnose definitively; frame as working impression / concern. " +
        "Do not invent vitals, medications, or exam findings not stated in EVIDENCE. " +
        "Output ONLY JSON matching the schema.\n\n" +
        `## EVIDENCE\n${digest}`
    );

    const schema = {
      type: "object",
      properties: {
        clinicalSynthesis: {
          type: "string",
          description: "3–5 sentences for the receiving ED team: mechanism/context, suspected category, stability cues, key unknowns.",
        },
        redFlags: {
          type: "array",
          items: { type: "string" },
          description: "Up to 8 short bullets: time-sensitive risks implied by EVIDENCE only.",
        },
        expectedInterventions: {
          type: "array",
          items: { type: "string" },
          description: "Up to 8 likely ED considerations (labs, imaging, monitoring) — conservative, evidence-grounded.",
        },
        handoverScript: {
          type: "string",
          description: "One short paragraph a paramedic could read at bay door; no fabricated numbers.",
        },
      },
      required: ["clinicalSynthesis", "redFlags", "expectedInterventions", "handoverScript"],
    };

    const ai = new GoogleGenAI({ apiKey: k });
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: [prompt],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 900,
        responseMimeType: "application/json",
        responseSchema: schema,
      },
    });

    const text = typeof response?.text === "function" ? response.text() : "";
    let parsed = null;
    if (text) {
      try {
        parsed = JSON.parse(text);
      } catch (_) {
        const m = text.match(/\{[\s\S]*\}/);
        if (m) {
          try {
            parsed = JSON.parse(m[0]);
          } catch (_) {}
        }
      }
    }

    if (!parsed || typeof parsed !== "object") {
      return {
        ok: false,
        error: "empty_parse",
        clinicalSynthesis: "",
        redFlags: [],
        expectedInterventions: [],
        handoverScript: "",
      };
    }

    const clinicalSynthesis = String(parsed.clinicalSynthesis || "").trim().slice(0, 2000);
    const redFlags = Array.isArray(parsed.redFlags)
      ? parsed.redFlags.map((x) => String(x)).filter(Boolean).slice(0, 8)
      : [];
    const expectedInterventions = Array.isArray(parsed.expectedInterventions)
      ? parsed.expectedInterventions.map((x) => String(x)).filter(Boolean).slice(0, 8)
      : [];
    const handoverScript = String(parsed.handoverScript || "").trim().slice(0, 1200);

    return {
      ok: true,
      clinicalSynthesis,
      redFlags,
      expectedInterventions,
      handoverScript,
    };
  } catch (e) {
    console.warn("[clinicalReport] generateClinicalReportCore failed:", e && e.message);
    return {
      ok: false,
      error: String((e && e.message) || e || "unknown").slice(0, 200),
      clinicalSynthesis: "",
      redFlags: [],
      expectedInterventions: [],
      handoverScript: "",
    };
  }
}

module.exports = { generateClinicalReportCore, buildClinicalDigest };
