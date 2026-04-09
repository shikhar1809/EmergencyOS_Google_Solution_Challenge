import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_os/features/map/domain/emergency_zone_classification.dart';

void main() {
  group('Hex grid constants', () {
    test('kZoneHexCircumRadiusM is 2400m', () {
      expect(kZoneHexCircumRadiusM, 2400.0);
    });

    test('kDispatchTier1RadiusM is 2400m', () {
      expect(kDispatchTier1RadiusM, 2400.0);
    });

    test('kDispatchTier2RadiusM is larger than Tier 1', () {
      expect(kDispatchTier2RadiusM, greaterThan(kDispatchTier1RadiusM));
    });

    test('kDispatchTier3RadiusM is larger than Tier 2', () {
      expect(kDispatchTier3RadiusM, greaterThan(kDispatchTier2RadiusM));
    });

    test('kMaxCoverageRadiusM is 45km', () {
      expect(kMaxCoverageRadiusM, 45000.0);
    });

    test('kZoneTierCount is 15', () {
      expect(kZoneTierCount, 15);
    });

    test('kZoneTierWidthM is 3000m', () {
      expect(kZoneTierWidthM, 3000.0);
    });
  });

  group('TierHealth enum', () {
    test('has 3 values', () {
      expect(TierHealth.values.length, 3);
    });

    test('contains green, yellow, red', () {
      expect(TierHealth.values, contains(TierHealth.green));
      expect(TierHealth.values, contains(TierHealth.yellow));
      expect(TierHealth.values, contains(TierHealth.red));
    });
  });

  group('HexAxial', () {
    test('storageKey format is q,r', () {
      const hex = HexAxial(3, -2);
      expect(hex.storageKey, '3,-2');
    });

    test('equality works', () {
      const a = HexAxial(1, 2);
      const b = HexAxial(1, 2);
      const c = HexAxial(1, 3);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
    });

    test('hashCode is consistent', () {
      const a = HexAxial(1, 2);
      const b = HexAxial(1, 2);
      expect(a.hashCode, b.hashCode);
    });

    test('tryParseStorageKey parses valid key', () {
      final hex = HexAxial.tryParseStorageKey('5,-3');
      expect(hex, isNotNull);
      expect(hex!.q, 5);
      expect(hex.r, -3);
    });

    test('tryParseStorageKey returns null for invalid key', () {
      expect(HexAxial.tryParseStorageKey('invalid'), isNull);
      expect(HexAxial.tryParseStorageKey(''), isNull);
      expect(HexAxial.tryParseStorageKey('5,'), isNull);
      expect(HexAxial.tryParseStorageKey(',3'), isNull);
    });
  });

  group('tierSummaryBucket', () {
    test('returns 0 for distance 0', () {
      expect(tierSummaryBucket(0), 0);
    });

    test('returns 1 for 3000m', () {
      expect(tierSummaryBucket(3000), 1);
    });

    test('returns higher bucket for larger distances', () {
      expect(tierSummaryBucket(6000), greaterThan(tierSummaryBucket(3000)));
    });
  });

  group('tierBandLabelKm', () {
    test('returns km label for tier 0', () {
      expect(tierBandLabelKm(0), contains('0'));
    });

    test('returns km label for tier 1', () {
      expect(tierBandLabelKm(1), contains('3'));
    });
  });
}
