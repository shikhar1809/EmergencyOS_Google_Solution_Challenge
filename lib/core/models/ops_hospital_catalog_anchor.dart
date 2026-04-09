/// Hospital anchor derived from the merged Places / offline catalog and Firestore.
class OpsHospitalCatalogAnchor {
  const OpsHospitalCatalogAnchor({
    required this.id,
    required this.name,
    required this.region,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final String region;
  final double lat;
  final double lng;
}
