import 'dart:math';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  final double latitude;
  final double longitude;
  final String label;
  final bool isLiveGps;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.isLiveGps,
  });
}

class LocationService {
  /// Default fallback coordinates (Sousse city center, Tunisia).
  static const UserLocation defaultSousseLocation = UserLocation(
    latitude: 35.8256,
    longitude: 10.6369,
    label: 'Sousse',
    isLiveGps: false,
  );

  /// Helpful preset areas (plus full 24-governorate list in [TunisiaDirectory]).
  static const List<UserLocation> presetLocations = [
    UserLocation(
      latitude: 35.8256,
      longitude: 10.6369,
      label: 'Sousse',
      isLiveGps: false,
    ),
    UserLocation(
      latitude: 35.8492,
      longitude: 10.6095,
      label: 'Khzema, Sousse',
      isLiveGps: false,
    ),
    UserLocation(
      latitude: 36.8065,
      longitude: 10.1815,
      label: 'Tunis',
      isLiveGps: false,
    ),
    UserLocation(
      latitude: 34.7406,
      longitude: 10.7603,
      label: 'Sfax',
      isLiveGps: false,
    ),
  ];

  /// Attempts to retrieve the device's real GPS location.
  /// Falls back cleanly to Sousse Centre if GPS is disabled or denied.
  static Future<UserLocation> getCurrentUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return defaultSousseLocation;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return defaultSousseLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return defaultSousseLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        label: 'My GPS Location',
        isLiveGps: true,
      );
    } catch (_) {
      return defaultSousseLocation;
    }
  }

  /// Calculates the geographic distance in kilometers using the Haversine formula.
  static double distanceInKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(endLat - startLat);
    final double dLng = _degreesToRadians(endLng - startLng);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(startLat)) *
            cos(_degreesToRadians(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180.0;
}
