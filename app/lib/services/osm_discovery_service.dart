import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/society_place.dart';

/// Live discovery of real Tunisian establishments (post offices, hospitals,
/// banks, municipalities) around any GPS point using OpenStreetMap Overpass API.
class OsmDiscoveryService {
  static const String _overpassEndpoint =
      'https://overpass-api.de/api/interpreter';

  /// Fetches real places within [radiusMeters] around ([latitude], [longitude]).
  static Future<List<SocietyPlace>> fetchNearbyRealPlaces({
    required double latitude,
    required double longitude,
    required String fallbackCity,
    int radiusMeters = 6500,
    http.Client? client,
  }) async {
    final query = '''
[out:json][timeout:12];
(
  node["amenity"~"^(post_office|hospital|clinic|bank|townhall)\$"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"~"^(post_office|hospital|clinic|bank|townhall)\$"](around:$radiusMeters,$latitude,$longitude);
);
out center 45;
''';

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .post(
            Uri.parse(_overpassEndpoint),
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'FereghQueueApp/1.0 (Tunisia)',
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return const [];
      }

      return parseOverpassJson(
        response.body,
        fallbackCity: fallbackCity,
      );
    } catch (_) {
      return const [];
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Parses an OpenStreetMap Overpass JSON response into [SocietyPlace] models.
  static List<SocietyPlace> parseOverpassJson(
    String rawBody, {
    required String fallbackCity,
  }) {
    try {
      final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
      final elements = decoded['elements'] as List<dynamic>? ?? const [];
      final now = DateTime.now();
      final results = <SocietyPlace>[];

      for (final item in elements) {
        final map = item as Map<String, dynamic>;
        final tags = map['tags'] as Map<String, dynamic>? ?? const {};
        final amenity = tags['amenity'] as String? ?? '';
        final category = _mapAmenity(amenity);
        if (category == null) continue;

        final rawName = (tags['name'] as String?)?.trim() ??
            (tags['name:fr'] as String?)?.trim() ??
            (tags['operator'] as String?)?.trim() ??
            '';
        if (rawName.isEmpty) continue;

        double? lat = (map['lat'] as num?)?.toDouble();
        double? lng = (map['lon'] as num?)?.toDouble();
        if (lat == null || lng == null) {
          final center = map['center'] as Map<String, dynamic>?;
          lat = (center?['lat'] as num?)?.toDouble();
          lng = (center?['lon'] as num?)?.toDouble();
        }
        if (lat == null || lng == null) continue;

        // Keep strictly within Tunisia's geographic bounds
        if (lat < 30.2 || lat > 37.6 || lng < 7.4 || lng > 11.7) continue;

        final osmId = (map['id'] as num?)?.toInt() ?? rawName.hashCode;
        final city = (tags['addr:city'] as String?)?.trim().isNotEmpty == true
            ? (tags['addr:city'] as String).trim()
            : fallbackCity;
        final street = (tags['addr:street'] as String?)?.trim() ?? '';
        final address = street.isNotEmpty ? '$street, $city' : city;

        // Deterministic initial counter/ticket estimate until the establishment updates it live
        final seed = osmId.abs();
        final guichets = 2 + (seed % 4); // 2..5 active guichets
        final currentTicket = 30 + (seed % 70);
        final waiting = 4 + ((seed ~/ 7) % 38); // varies across Green / Yellow / Red
        final lastTicket = currentTicket + waiting;

        results.add(
          SocietyPlace(
            id: 'osm_$osmId',
            name: rawName,
            city: city,
            address: address,
            category: category,
            latitude: lat,
            longitude: lng,
            guichetCount: guichets,
            lastTicketNumber: lastTicket,
            currentTicketNumber: currentTicket,
            calculatedWaitMinutes: SocietyPlace.calculateWaitMinutes(
              lastTicket: lastTicket,
              currentTicket: currentTicket,
              guichets: guichets,
            ),
            lastCalculatedAt: now,
          ),
        );
      }

      return results;
    } catch (_) {
      return const [];
    }
  }

  static PlaceCategory? _mapAmenity(String amenity) {
    switch (amenity) {
      case 'post_office':
        return PlaceCategory.post;
      case 'hospital':
      case 'clinic':
        return PlaceCategory.hospital;
      case 'bank':
        return PlaceCategory.bank;
      case 'townhall':
        return PlaceCategory.municipality;
      default:
        return null;
    }
  }
}
