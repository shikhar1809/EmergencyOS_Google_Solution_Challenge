import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:emergency_os/features/map/domain/emergency_zone_classification.dart';
import 'package:emergency_os/services/places_service.dart';

void main() {
  group('tierHealthForCell', () {
    test('red when no hospital', () {
      expect(
        tierHealthForCell(const HexCellCoverage(hospitals: 0, volunteers: 1)),
        TierHealth.red,
      );
    });

    test('green when hospital and volunteer', () {
      expect(
        tierHealthForCell(const HexCellCoverage(hospitals: 1, volunteers: 1)),
        TierHealth.green,
      );
    });

    test('green when hospital and volunteer', () {
      expect(
        tierHealthForCell(const HexCellCoverage(hospitals: 1, volunteers: 2)),
        TierHealth.green,
      );
    });

    test('yellow when hospital only', () {
      expect(
        tierHealthForCell(const HexCellCoverage(hospitals: 1, volunteers: 0)),
        TierHealth.yellow,
      );
    });
  });

  group('buildEmergencyHexZones', () {
    test('produces polygons and summaries for Lucknow center', () {
      const center = LatLng(26.8467, 80.9462);
      final hospitals = [
        EmergencyPlace(
          name: 'Test Hospital',
          vicinity: 'Near center',
          lat: center.latitude + 0.01,
          lng: center.longitude + 0.01,
          placeId: 'h1',
        ),
      ];
      final model = buildEmergencyHexZones(
        center: center,
        hospitals: hospitals,
        volunteerPositions: const [],
      );
      expect(model.polygons, isNotEmpty);
      expect(model.totalCells, greaterThan(0));
      expect(model.coveragePercent, greaterThanOrEqualTo(0));
      expect(model.coveragePercent, lessThanOrEqualTo(100));
    });
  });

  group('tierSummaryBucket', () {
    test('maps distance to tier index', () {
      expect(tierSummaryBucket(0), 0);
      expect(tierSummaryBucket(3500), 1);
      expect(tierSummaryBucket(14900), kZoneTierCount - 1);
    });
  });
}
