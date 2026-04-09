/// PNG markers bundled under `Map_Marker/` (see `pubspec.yaml`).
///
/// Vehicle sprites are drawn with **top = north** so [Marker.rotation] can use
/// compass bearing (0° north, clockwise) with [Marker.flat] and anchor (0.5, 0.5).
abstract final class MapMarkerAssets {
  // —— Facilities (station / building pins) ——
  static const String hospital = 'Map_Marker/Hospital_Map_Maker.png';

  // —— Vehicles (rotating / flat markers; art faces **up** = north) ——
  static const String ambulance = 'Map_Marker/Ambulance_Map_Marker.png';

  static const String volunteerMale = 'Map_Marker/Volenteer_Male_Map_Marker.png';
  static const String volunteerFemale = 'Map_Marker/Volenteer_Female_Map_Marker.png';

  /// Logical width for facility pins (dp-ish; passed to image decode scale).
  static const int stationWidthPx = 96;

  /// Fleet / operator vehicle widths are tiered by zoom in FleetMapIcons.
  static const int volunteerWidthPx = 96;
}
