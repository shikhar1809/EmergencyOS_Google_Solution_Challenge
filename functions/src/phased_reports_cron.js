const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getFunctions } = require("firebase-admin/functions");

/**
 * Sweeps active SOS incidents every minute.
 * Creates stagger-generated "Live Report" updates at Minute 3, 6, and 9 of the Golden Hour.
 */
exports.progressPhasedLiveReports = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "UTC",
    memory: "512MiB",
    cpu: 0.5,
    timeoutSeconds: 180,
  },
  async () => {
    const db = getFirestore();
    const activeStatuses = ["pending", "dispatched", "blocked"];
    
    // Safety check - we don't want to scan the whole DB forever, just the active ones
    // Firestore lacks "IN" on large scale, so we query just "pending" and "dispatched" usually
    // but in V2 we can just query 'status' in [...]
    const snaps = await db.collection("sos_incidents")
      .where("status", "in", activeStatuses)
      .limit(60)
      .get();

    if (snaps.empty) {
      console.log("[progressPhasedLiveReports] No active incidents to process.");
      return;
    }

    const now = Date.now();
    let updatedCount = 0;

    for (const doc of snaps.docs) {
      const data = doc.data();
      const timestamp = data.timestamp;
      if (!timestamp) continue;
      
      const secondsElapsed = (now - timestamp.toMillis()) / 1000;
      const minutesElapsed = Math.floor(secondsElapsed / 60);

      const targetPhase = minutesElapsed >= 9 ? 3 
                         : minutesElapsed >= 6 ? 2 
                         : minutesElapsed >= 3 ? 1 
                         : 0;

      const currentPhase = Number(data.liveReportPhase || 0);

      // Only process if we've crossed a minute threshold AND haven't run that phase yet
      if (targetPhase > currentPhase) {
        console.log(`[progressPhasedLiveReports] Incident ${doc.id} entered Phase ${targetPhase} (elapsed: ${minutesElapsed}m). Executing...`);
        let newReportData = data.liveReportData || {};
        
        try {
          if (targetPhase === 1 && currentPhase < 1) {
            // Minute 3: Essentials & Basic Medical Info
            newReportData = {
              ...newReportData,
              patientEssentials: {
                name: data.userDisplayName || "Unknown",
                bloodType: data.bloodType || "—",
                allergies: data.allergies || "—",
                medicalConditions: data.medicalConditions || "—",
                emergencyType: data.type || "—",
                contactPhone: data.emergencyContactPhone || "—",
                intakeQuestions: data.triage || {},
              },
              phase1GeneratedAt: FieldValue.serverTimestamp()
            };
          }

          if (targetPhase === 2 && currentPhase < 2) {
            // Minute 6: AI Situation Brief using Gemini
            let briefText = "Insufficient scene data to generate AI brief at Min 6.";
            if (data.volunteerSceneReport && Object.keys(data.volunteerSceneReport).length > 0) {
              briefText = "Volunteer on-scene report detected. Scene describes: " + 
                          (data.volunteerSceneReport.incidentDescription || "Unknown") + ". " + 
                          (data.volunteerSceneReport.voiceNoteTranscript || "");
            }
            
            // To emulate Gemini (since Admin SDK doesn't natively call callable functions),
            // we build the brief from the available fields directly.
            newReportData = {
              ...newReportData,
              situationBrief: briefText,
              onScenePhotosCount: (data.volunteerSceneReport?.photoPaths || []).length,
              phase2GeneratedAt: FieldValue.serverTimestamp()
            };
          }

          if (targetPhase === 3 && currentPhase < 3) {
            // Minute 9: EMR Handoff requirements and full scene context
            newReportData = {
              ...newReportData,
              emrHandoff: {
                dispatchStatus: data.status,
                fleetAccepted: data.emsAcceptedAt ? "Yes" : "No",
                etaRequiredServices: data.preArrivalHandoff?.prepareRoom || [],
                ambulanceEta: data.ambulanceEta || "Unknown",
              },
              phase3GeneratedAt: FieldValue.serverTimestamp()
            };
          }

          // Commit to Firestore
          await doc.ref.update({
            liveReportPhase: targetPhase,
            liveReportData: newReportData,
            updatedAt: FieldValue.serverTimestamp()
          });
          updatedCount++;
        } catch (e) {
          console.error(`[progressPhasedLiveReports] Failed Phase ${targetPhase} for ${doc.id}:`, e);
        }
      }
    }

    if (updatedCount > 0) {
      console.log(`[progressPhasedLiveReports] Successfully progressed ${updatedCount} incidents.`);
    }
  }
);
