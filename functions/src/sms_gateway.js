const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { db, FieldValue } = require("./utils");

const twilioSid = process.env.TWILIO_ACCOUNT_SID;
const twilioToken = process.env.TWILIO_AUTH_TOKEN;
const twilioNumber = (process.env.TWILIO_PHONE_NUMBER || "").trim();
let twilioClient;
if (twilioSid && twilioToken) {
  twilioClient = require("twilio")(twilioSid, twilioToken);
}

exports.parseSmsGateway = onRequest(async (req, res) => {
  if (req.method !== "POST") return res.status(405).send("Method not allowed");
  const body = req.body;
  const from = body.From || "";
  const text = body.Body || "";
  const geoMatch = text.match(/geo:-?(\d+\.\d+),-?(\d+\.\d+)/);
  if (!geoMatch) {
    return res.status(200).send("No location found. Send: geo:lat,lng SOS");
  }
  const lat = parseFloat(geoMatch[1]);
  const lng = parseFloat(geoMatch[2]);
  try {
    const ref = await db.collection("sos_incidents").add({
      lat, lng, type: "SMS SOS", userId: "sms_unknown",
      userDisplayName: `SMS from ${from}`,
      status: "pending", timestamp: FieldValue.serverTimestamp(),
      source: "sms_gateway", smsFrom: from,
    });
    return res.status(200).send(`SOS logged. ID: ${ref.id}`);
  } catch (e) {
    console.error("SMS gateway error:", e);
    return res.status(500).send("Error processing SOS");
  }
});

exports.onIncidentUpdate = onDocumentUpdated("sos_incidents/{id}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  const statusChanged = before.status !== after.status;
  if (!statusChanged) return;
  const contactPhone = after.emergencyContactPhone;
  if (!contactPhone || !twilioClient) return;
  try {
    await twilioClient.messages.create({
      body: `EmergencyOS: SOS ${event.params.id} status changed to ${after.status}.`,
      from: twilioNumber,
      to: contactPhone,
    });
  } catch (e) {
    console.warn("SMS update failed:", e);
  }
});

exports.notifyEmergencyContactOnUpdate = onDocumentUpdated("sos_incidents/{id}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (!after.emergencyContactPhone || !after.useEmergencyContactForSms) return;
  if (!twilioClient) return;
  const statusChanged = before.status !== after.status;
  const etaChanged = before.ambulanceEta !== after.ambulanceEta;
  if (!statusChanged && !etaChanged) return;
  try {
    let msg = `EmergencyOS update for incident ${event.params.id}:`;
    if (statusChanged) msg += ` Status: ${after.status}.`;
    if (etaChanged && after.ambulanceEta) msg += ` Ambulance ETA: ${after.ambulanceEta}.`;
    await twilioClient.messages.create({ body: msg, from: twilioNumber, to: after.emergencyContactPhone });
  } catch (e) {
    console.warn("Emergency contact SMS failed:", e);
  }
});
