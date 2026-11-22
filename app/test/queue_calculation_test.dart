import 'package:flutter_test/flutter_test.dart';
import 'package:queue_time_app/models/society_place.dart';
import 'package:queue_time_app/services/location_service.dart';

void main() {
  group('Queue Waiting Time Formula', () {
    test('matches example: last=150, current=100, guichets=5 -> 50 min (Crowded)', () {
      final wait = SocietyPlace.calculateWaitMinutes(
        lastTicket: 150,
        currentTicket: 100,
        guichets: 5,
      );

      expect(wait, 50);
      expect(SocietyPlace.statusForWaitMinutes(wait), CrowdStatus.crowded);
    });

    test('classifies 40+ min as Crowded (Red)', () {
      expect(SocietyPlace.statusForWaitMinutes(40), CrowdStatus.crowded);
      expect(SocietyPlace.statusForWaitMinutes(65), CrowdStatus.crowded);
    });

    test('classifies 20 to 39 min as Moderate (Yellow)', () {
      expect(SocietyPlace.statusForWaitMinutes(20), CrowdStatus.moderate);
      expect(SocietyPlace.statusForWaitMinutes(30), CrowdStatus.moderate);
      expect(SocietyPlace.statusForWaitMinutes(39), CrowdStatus.moderate);
    });

    test('classifies under 20 min as Not Crowded (Green)', () {
      expect(SocietyPlace.statusForWaitMinutes(0), CrowdStatus.notCrowded);
      expect(SocietyPlace.statusForWaitMinutes(15), CrowdStatus.notCrowded);
      expect(SocietyPlace.statusForWaitMinutes(19), CrowdStatus.notCrowded);
    });

    test('handles zero or negative queue safely', () {
      final wait = SocietyPlace.calculateWaitMinutes(
        lastTicket: 80,
        currentTicket: 90,
        guichets: 4,
      );
      expect(wait, 0);
      expect(SocietyPlace.statusForWaitMinutes(wait), CrowdStatus.notCrowded);
    });
  });

  group('Haversine Distance', () {
    test('returns ~0 km for identical coordinates', () {
      final km = LocationService.distanceInKm(
        startLat: 35.8256,
        startLng: 10.6369,
        endLat: 35.8256,
        endLng: 10.6369,
      );
      expect(km, closeTo(0.0, 0.001));
    });

    test('computes realistic distance inside Sousse', () {
      final km = LocationService.distanceInKm(
        startLat: 35.8256,
        startLng: 10.6369,
        endLat: 35.8458,
        endLng: 10.6145,
      );
      expect(km, greaterThan(2.0));
      expect(km, lessThan(4.0));
    });
  });
}
