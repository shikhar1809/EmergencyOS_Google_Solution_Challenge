const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { db, FieldValue, leaderboardDisplayNameFromUserDoc } = require("./utils");

async function updateLeaderboardForUser(uid) {
  try {
    const userSnap = await db.collection("users").doc(uid).get();
    if (!userSnap.exists) return;
    const user = userSnap.data();
    const incidentsSnap = await db.collection("sos_incidents").where("acceptedVolunteerIds", "array-contains", uid).where("status", "==", "resolved").get();
    const livesSaved = incidentsSnap.docs.length;
    const xp = Math.max(0, Math.floor(user.volunteerXp || 0));
    const dutyMinutes = Math.max(0, Math.floor(user.dutyMinutes || 0));
    await db.collection("leaderboard").doc(uid).set({
      uid,
      displayName: leaderboardDisplayNameFromUserDoc(user, uid),
      volunteerXp: xp,
      volunteerLivesSaved: livesSaved,
      dutyMinutes,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  } catch (e) {
    console.warn("Leaderboard update failed for", uid, e);
  }
}

exports.updateLeaderboardOnIncidentChange = onDocumentCreated("sos_incidents/{id}", async (event) => {
  const data = event.data?.data();
  if (!data) return;
  const volunteerIds = Array.isArray(data.acceptedVolunteerIds) ? data.acceptedVolunteerIds : [];
  for (const uid of volunteerIds) {
    await updateLeaderboardForUser(uid);
  }
  if (data.userId && data.userId !== "anon" && data.userId !== "sms_unknown") {
    await updateLeaderboardForUser(data.userId);
  }
});
