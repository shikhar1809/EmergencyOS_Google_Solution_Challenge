import 'app_constants.dart';

/// Dark, high-contrast “dispatch / ops” basemap for [GoogleMap] when no Cloud Map ID is set.
/// Near-black land, stepped road hierarchy (locals → arterials → amber motorways), deep water.
const String kGoogleMapsEmergencyResponseDarkStyleJson = r'''
[
  {"elementType": "geometry", "stylers": [{"color": "#0c0f13"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#c5d4e8"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0c0f13"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"visibility": "off"}]},
  {"featureType": "administrative", "elementType": "labels.text.fill", "stylers": [{"color": "#79C0FF"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "administrative.neighborhood", "stylers": [{"visibility": "simplified"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#79C0FF"}]},
  {"featureType": "landscape", "elementType": "geometry", "stylers": [{"color": "#101418"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry", "stylers": [{"color": "#151a20"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#0e1318"}]},
  {"featureType": "poi", "stylers": [{"visibility": "simplified"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#79C0FF"}]},
  {"featureType": "poi", "elementType": "labels.text.stroke", "stylers": [{"color": "#0c0f13"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.medical", "elementType": "geometry", "stylers": [{"color": "#1a2838"}]},
  {"featureType": "poi.government", "elementType": "geometry", "stylers": [{"color": "#1a242e"}]},
  {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#121c16"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2a3f5c"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#1a2533"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#79C0FF"}]},
  {"featureType": "road", "elementType": "labels.text.stroke", "stylers": [{"color": "#0c0f13"}]},
  {"featureType": "road.local", "elementType": "geometry", "stylers": [{"color": "#2f4a6b"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#3d6ba3"}]},
  {"featureType": "road.highway", "elementType": "geometry.fill", "stylers": [{"color": "#4A90D9"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#2a5a9a"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0a1628"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#79C0FF"}]},
  {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#061525"}]}
]
''';

/// Inline JSON is ignored when [AppConstants.googleMapsDarkMapId] is set (Cloud Map style wins).
String? effectiveGoogleMapsEmbeddedStyleJson() =>
    AppConstants.googleMapsDarkMapId.isEmpty ? kGoogleMapsEmergencyResponseDarkStyleJson : null;
