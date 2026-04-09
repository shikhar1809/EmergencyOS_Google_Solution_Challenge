/// Suppresses Google’s default clickable hospital / business POIs on the basemap so
/// command-center facilities come only from the Places merge and `ops_hospitals` data.
///
/// Note: If you rely solely on a Cloud Map ID with POIs baked into that style, adjust
/// the style in Google Cloud Console as well; this JSON is merged where the platform supports it.
const String kGoogleMapsCommandCenterSuppressDefaultFacilityPoisJson = r'''
[
  {"featureType": "poi.medical", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]}
]
''';
