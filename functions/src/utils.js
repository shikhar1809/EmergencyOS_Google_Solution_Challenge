// Shared utilities used across all Cloud Functions modules.
const admin = require("firebase-admin");
const { geohashForPoint, geohashQueryBounds, distanceBetween } = require("geofire-common");

const db = admin.firestore();
const { FieldValue } = admin.firestore;

const EARTH_RADIUS_KM = 6371;
const ALERT_RADIUS_KM = 20;

const OPS_ZONES = [
  { id: "lucknow",         lat: 26.8467, lng: 80.9462, radiusKm: 120 },
  { id: "delhi_ncr",       lat: 28.6139, lng: 77.2090, radiusKm:  85 },
  { id: "mumbai",          lat: 19.0760, lng: 72.8777, radiusKm:  75 },
  { id: "bengaluru",       lat: 12.9716, lng: 77.5946, radiusKm:  65 },
  { id: "hyderabad",       lat: 17.3850, lng: 78.4867, radiusKm:  70 },
  { id: "chennai",         lat: 13.0827, lng: 80.2707, radiusKm:  70 },
  { id: "kolkata",         lat: 22.5726, lng: 88.3639, radiusKm:  75 },
  { id: "north_india_wide",lat: 28.6000, lng: 77.5000, radiusKm: 650 },
];

const OPS_ZONE_CENTER = OPS_ZONES[0];
const ZONE_HEX_CIRCUM_RADIUS_M = 2400.0;

function degreesToRadians(deg) { return deg * (Math.PI / 180); }

function getClosestOpsZone(lat, lng) {
  let best = OPS_ZONES[0];
  let bestKm = distanceBetween([lat, lng], [best.lat, best.lng]);
  for (let i = 1; i < OPS_ZONES.length; i++) {
    const z = OPS_ZONES[i];
    if (z.id === "north_india_wide") continue;
    const km = distanceBetween([lat, lng], [z.lat, z.lng]);
    if (km < bestKm) { bestKm = km; best = z; }
  }
  return best;
}

function _metersPerDegLat() { return 111320.0; }
function _metersPerDegLng(atLat) { return 111320.0 * Math.cos(degreesToRadians(atLat)); }
function _enuOffsetMeters(centerLat, centerLng, lat, lng) {
  const y = (lat - centerLat) * _metersPerDegLat();
  const x = (lng - centerLng) * _metersPerDegLng(centerLat);
  return { x, y };
}
function _hexRound(fq, fr) {
  let q = Math.round(fq);
  let r = Math.round(fr);
  const fs = -fq - fr;
  const s = Math.round(fs);
  const qDiff = Math.abs(q - fq);
  const rDiff = Math.abs(r - fr);
  const sDiff = Math.abs(s - fs);
  if (qDiff > rDiff && qDiff > sDiff) q = -r - s;
  else if (rDiff > sDiff) r = -q - s;
  return { q, r };
}
function _worldMetersToHex(size, x, y) {
  const fq = (2.0 / 3.0 * x) / size;
  const fr = (-1.0 / 3.0 * x + Math.sqrt(3.0) / 3.0 * y) / size;
  return _hexRound(fq, fr);
}
function latLngToHex(lat, lng, zoneOverride) {
  const zone = zoneOverride || getClosestOpsZone(lat, lng);
  const enu = _enuOffsetMeters(zone.lat, zone.lng, lat, lng);
  return _worldMetersToHex(ZONE_HEX_CIRCUM_RADIUS_M, enu.x, enu.y);
}
function hexAxialDistance(h1, h2) {
  const x1 = h1.q, z1 = h1.r, y1 = -h1.q - h1.r;
  const x2 = h2.q, z2 = h2.r, y2 = -h2.q - h2.r;
  return Math.max(Math.abs(x1 - x2), Math.abs(y1 - y2), Math.abs(z1 - z2));
}
function haversineKm(lat1, lng1, lat2, lng2) {
  const dLat = degreesToRadians(lat2 - lat1);
  const dLng = degreesToRadians(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(degreesToRadians(lat1)) * Math.cos(degreesToRadians(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a));
}

async function _writeOpsDashboardAlert({ incidentId, kind, title, body, severity = "info", extra = {} }) {
  const ref = db.collection("ops_dashboard_alerts").doc();
  await ref.set({ incidentId, kind, title, body, severity, createdAt: FieldValue.serverTimestamp(), acked: false, ...extra });
}

function mergeRequiredServicesFromIncident(incident) {
  const base = Array.isArray(incident.requiredServices) ? incident.requiredServices.map((s) => String(s)).filter((s) => s.trim() !== "") : [];
  const dh = incident.dispatchHints && typeof incident.dispatchHints === "object" ? incident.dispatchHints : {};
  const hint = Array.isArray(dh.requiredServices) ? dh.requiredServices.map((s) => String(s)).filter((s) => s.trim() !== "") : [];
  const seen = new Set();
  const out = [];
  for (const x of [...base, ...hint]) {
    const k = x.toLowerCase();
    if (!seen.has(k)) { seen.add(k); out.push(k); }
    if (out.length >= 12) break;
  }
  return out;
}

function emergencyTypeLower(incident) {
  const dh = incident.dispatchHints && typeof incident.dispatchHints === "object" ? incident.dispatchHints : {};
  return String(incident.type || dh.emergencyType || "").toLowerCase();
}

function numLike(v, d) {
  if (v == null) return d;
  if (typeof v === "number" && !Number.isNaN(v)) return v;
  if (typeof v === "string" && v.trim() !== "") { const n = Number(v); return Number.isNaN(n) ? d : n; }
  return d;
}

function volunteerEliteEligible(userDoc) {
  const u = userDoc || {};
  const cleared = Math.max(0, Math.min(99, Math.floor(numLike(u.lifelineLevelsCleared, 0))));
  const lives = Math.max(0, Math.floor(numLike(u.volunteerLivesSaved, 0)));
  const xp = Math.max(0, Math.floor(numLike(u.volunteerXp, 0)));
  if (cleared >= 10) return true;
  if (lives >= 5 && xp >= 1000) return true;
  return false;
}

function leaderboardDisplayNameFromUserDoc(user, uid) {
  const u = user || {};
  const uidStr = typeof uid === "string" ? uid : "";
  if (typeof u.displayName === "string" && u.displayName.trim()) return u.displayName.trim();
  if (typeof u.name === "string" && u.name.trim()) return u.name.trim();
  if (typeof u.email === "string" && u.email.includes("@")) {
    const local = u.email.split("@")[0].trim();
    if (local) return local.charAt(0).toUpperCase() + local.slice(1).toLowerCase();
  }
  if (typeof u.phoneNumber === "string" && u.phoneNumber.trim()) return u.phoneNumber.trim();
  if (uidStr.length >= 6) return `Member ${uidStr.slice(0, 6)}`;
  return "Member";
}

function timestampToMillis(value) {
  if (!value) return null;
  if (typeof value === "string") { const ms = Date.parse(value); return Number.isNaN(ms) ? null : ms; }
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value.toMillis === "function") { try { return value.toMillis(); } catch (_) { return null; } }
  return null;
}

module.exports = {
  db,
  FieldValue,
  OPS_ZONES,
  OPS_ZONE_CENTER,
  ZONE_HEX_CIRCUM_RADIUS_M,
  degreesToRadians,
  getClosestOpsZone,
  latLngToHex,
  hexAxialDistance,
  haversineKm,
  _writeOpsDashboardAlert,
  mergeRequiredServicesFromIncident,
  emergencyTypeLower,
  numLike,
  volunteerEliteEligible,
  leaderboardDisplayNameFromUserDoc,
  timestampToMillis,
  geohashForPoint,
  geohashQueryBounds,
  distanceBetween,
};
