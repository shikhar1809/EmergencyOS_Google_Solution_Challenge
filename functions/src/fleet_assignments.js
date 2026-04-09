const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { db, FieldValue } = require("./utils");

exports.onFleetPendingAssignmentCreated = onDocumentCreated("fleet_assignments/{id}", async (event) => {
  const data = event.data?.data();
  if (!data || data.status !== "pending") return;
  try {
    const fcmToken = data.operatorFcmToken;
    if (!fcmToken) return;
    await admin.messaging().send({
      token: fcmToken,
      data: { type: "fleet_assignment", assignmentId: event.params.id, incidentId: data.incidentId || "" },
      notification: { title: "New Fleet Assignment", body: `Incident ${data.incidentId || "assigned"}. Tap to accept.` },
    });
  } catch (e) {
    console.error("Fleet assignment notification failed:", e);
  }
});

exports.onHospitalAssignmentAcceptedDispatchAmbulance = onDocumentUpdated("ops_incident_hospital_assignments/{id}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.dispatchStatus === "accepted" || after.dispatchStatus !== "accepted") return;
  try {
    const incidentId = event.params.id;
    const incidentSnap = await db.collection("sos_incidents").doc(incidentId).get();
    if (!incidentSnap.exists) return;
    const incident = incidentSnap.data();
    await db.collection("fleet_assignments").add({
      incidentId,
      status: "pending",
      hospitalId: after.acceptedHospitalId || after.notifiedHospitalId,
      incidentLat: incident.lat,
      incidentLng: incident.lng,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error("Ambulance dispatch on hospital accept failed:", e);
  }
});

exports.refreshHospitalDispatchOnDispatchHints = onDocumentUpdated("sos_incidents/{id}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  const beforeHints = JSON.stringify(before.dispatchHints || {});
  const afterHints = JSON.stringify(after.dispatchHints || {});
  if (beforeHints === afterHints) return;
  if (after.status !== "pending" && after.status !== "dispatched") return;
  try {
    const { dispatchHospitalInHex } = require("./hospital_chain");
    await dispatchHospitalInHex({ incidentId: event.params.id, incident: after });
  } catch (e) {
    console.warn("Re-dispatch on hints change failed:", e);
  }
});

exports.redispatchOnRequiredServicesChange = onDocumentUpdated("sos_incidents/{id}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  const beforeSvc = JSON.stringify(before.requiredServices || []);
  const afterSvc = JSON.stringify(after.requiredServices || []);
  if (beforeSvc === afterSvc) return;
  if (after.status !== "pending" && after.status !== "dispatched") return;
  try {
    const { dispatchHospitalInHex } = require("./hospital_chain");
    await dispatchHospitalInHex({ incidentId: event.params.id, incident: after });
  } catch (e) {
    console.warn("Redispatch on services change failed:", e);
  }
});

exports.acceptAmbulanceDispatch = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "User must be authenticated.");
  const { assignmentId } = request.data;
  if (!assignmentId) throw new HttpsError("invalid-argument", "assignmentId required");
  const ref = db.collection("fleet_assignments").doc(assignmentId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Assignment not found");
  await ref.set({ status: "accepted", acceptedBy: request.auth.uid, acceptedAt: FieldValue.serverTimestamp(), ambulanceDispatchStatus: "ambulance_en_route" }, { merge: true });
  return { success: true };
});

exports.ambulanceDispatchEscalation = onSchedule({ schedule: "every 2 minutes", timeoutSeconds: 120 }, async () => {
  const snaps = await db.collection("fleet_assignments").where("status", "==", "pending").get();
  const timeoutMs = 5 * 60 * 1000;
  for (const doc of snaps.docs) {
    const d = doc.data();
    const createdAt = d.createdAt;
    if (!createdAt || !createdAt.toMillis) continue;
    if (Date.now() - createdAt.toMillis() > timeoutMs) {
      await doc.ref.set({ status: "no_operator", escalatedAt: FieldValue.serverTimestamp() }, { merge: true });
    }
  }
});

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
