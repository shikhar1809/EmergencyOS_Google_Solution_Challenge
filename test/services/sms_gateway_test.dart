import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_os/core/constants/app_constants.dart';
import 'package:emergency_os/services/sms_gateway_service.dart';

void main() {
  group('SmsGatewayService', () {
    test('buildGeoSms includes URL, coordinates, type, and GeoSMS marker', () {
      final body = SmsGatewayService.buildGeoSms(
        lat: 26.8467,
        lng: 80.9462,
        type: 'Cardiac',
        victimCount: 1,
        freeText: 'Test note',
        incidentId: 'inc-123',
      );
      expect(body, contains(AppConstants.geoSmsBaseUrl));
      expect(body, contains('26.846700'));
      expect(body, contains('80.946200'));
      expect(body, contains('&GeoSMS'));
      expect(body, contains('CARDIAC'));
      expect(body, contains('incidentId'));
      expect(body, contains('EmergencyOS Alert'));
    });

    test('buildGeoSms uses Victims plural when count > 1', () {
      final body = SmsGatewayService.buildGeoSms(
        lat: 1,
        lng: 2,
        type: 'Fire',
        victimCount: 3,
      );
      expect(body.split('\n')[1], contains('Victims: 3'));
    });

    test('parseGeoSms round-trips buildGeoSms', () {
      final built = SmsGatewayService.buildGeoSms(
        lat: 12.345678,
        lng: 98.765432,
        type: 'Test Type',
        victimCount: 2,
        freeText: 'extra',
        incidentId: 'abc',
      );
      final parsed = SmsGatewayService.parseGeoSms(built, senderNumber: '+15550001');
      expect(parsed, isNotNull);
      expect(parsed!.latitude, closeTo(12.345678, 0.000001));
      expect(parsed.longitude, closeTo(98.765432, 0.000001));
      expect(parsed.victimCount, 2);
      expect(parsed.senderNumber, '+15550001');
      expect(parsed.incidentId, 'abc');
    });

    test('parseGeoSms returns null for non-GeoSMS text', () {
      expect(SmsGatewayService.parseGeoSms('hello world'), isNull);
    });
  });
}
