import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/tunisia_places.dart';
import '../models/society_place.dart';
import 'location_service.dart';
import 'osm_discovery_service.dart';

enum PlaceSortMode {
  bestRecommended, // Combines lowest wait time + nearest distance
  lowestWait,      // Lowest waiting time first
  nearestDistance, // Closest physical distance first
}

class RecalculationLog {
  final DateTime timestamp;
  final int placesUpdated;
  final bool wasAutomatic;

  const RecalculationLog({
    required this.timestamp,
    required this.placesUpdated,
    required this.wasAutomatic,
  });
}

class QueueProvider extends ChangeNotifier {
  static const String _storageKeyPlaces = 'queue_time_places_tunisia_v2';
  static const String _storageKeyInterval = 'queue_time_interval_v1';

  List<SocietyPlace> _places = [];
  UserLocation _userLocation = LocationService.defaultSousseLocation;
  bool _isLoadingLocation = false;
  bool _isDiscoveringOsm = false;
  int _lastOsmAddedCount = 0;

  /// Automatic recalculation interval in minutes (either 2 or 5).
  int _refreshIntervalMinutes = 2;
  int _secondsUntilNextRefresh = 120;
  Timer? _periodicRecalcTimer;
  Timer? _countdownTimer;

  final List<RecalculationLog> _logs = [];

  /// Selected society requested to be focused on the Map tab.
  String? _focusedMapPlaceId;

  List<SocietyPlace> get places => List.unmodifiable(_places);
  UserLocation get userLocation => _userLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isDiscoveringOsm => _isDiscoveringOsm;
  int get lastOsmAddedCount => _lastOsmAddedCount;
  int get refreshIntervalMinutes => _refreshIntervalMinutes;
  int get secondsUntilNextRefresh => _secondsUntilNextRefresh;
  List<RecalculationLog> get logs => List.unmodifiable(_logs);
  String? get focusedMapPlaceId => _focusedMapPlaceId;

  /// All governorates currently represented in the directory.
  List<String> get availableGovernorates => TunisiaDirectory.governorateNames;

  String get formattedCountdown {
    final minutes = _secondsUntilNextRefresh ~/ 60;
    final seconds = _secondsUntilNextRefresh % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  QueueProvider() {
    _places = TunisiaDirectory.buildAllTunisiaPlaces();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedInterval = prefs.getInt(_storageKeyInterval);
    if (savedInterval == 2 || savedInterval == 5) {
      _refreshIntervalMinutes = savedInterval!;
    }

    final savedPlacesJson = prefs.getString(_storageKeyPlaces);
    if (savedPlacesJson != null && savedPlacesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedPlacesJson) as List<dynamic>;
        if (decoded.isNotEmpty) {
          _places = decoded
              .map((e) => SocietyPlace.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        _places = TunisiaDirectory.buildAllTunisiaPlaces();
      }
    } else {
      await _persistPlaces();
    }

    recalculateAllWaitTimes(automatic: false);
    _startPeriodicTimers();
    await refreshUserLocation();
  }

  /// Starts the automatic periodic calculation timer (every 2 or 5 minutes).
  void _startPeriodicTimers() {
    _periodicRecalcTimer?.cancel();
    _countdownTimer?.cancel();

    _secondsUntilNextRefresh = _refreshIntervalMinutes * 60;

    _periodicRecalcTimer = Timer.periodic(
      Duration(minutes: _refreshIntervalMinutes),
      (_) {
        recalculateAllWaitTimes(automatic: true);
        _secondsUntilNextRefresh = _refreshIntervalMinutes * 60;
      },
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsUntilNextRefresh > 0) {
        _secondsUntilNextRefresh--;
        notifyListeners();
      }
    });
  }

  /// Switches the automatic recalculation interval between 2 min and 5 min.
  Future<void> setRefreshIntervalMinutes(int minutes) async {
    if (minutes != 2 && minutes != 5) return;
    _refreshIntervalMinutes = minutes;
    _startPeriodicTimers();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKeyInterval, minutes);
  }

  /// Core periodic calculation function:
  ///   waitingPeople = lastTicket - currentTicket
  ///   peoplePerGuichet = waitingPeople / guichetCount
  ///   waitMinutes = peoplePerGuichet * 5
  void recalculateAllWaitTimes({bool automatic = false}) {
    final now = DateTime.now();
    _places = _places.map((place) => place.recalculated(now)).toList();

    _logs.insert(
      0,
      RecalculationLog(
        timestamp: now,
        placesUpdated: _places.length,
        wasAutomatic: automatic,
      ),
    );
    if (_logs.length > 20) {
      _logs.removeLast();
    }

    if (!automatic) {
      _secondsUntilNextRefresh = _refreshIntervalMinutes * 60;
    }

    _persistPlaces();
    notifyListeners();
  }

  /// Retrieves live GPS coordinates (or defaults cleanly to Sousse).
  Future<void> refreshUserLocation() async {
    _isLoadingLocation = true;
    notifyListeners();

    _userLocation = await LocationService.getCurrentUserLocation();

    _isLoadingLocation = false;
    notifyListeners();
  }

  /// Allows selecting any of Tunisia's 24 governorates or custom test location.
  void setCustomUserLocation(UserLocation location) {
    _userLocation = location;
    notifyListeners();
  }

  /// Fetches live real-world establishments from OpenStreetMap Overpass API
  /// around the user's location or any map center in Tunisia.
  /// Returns the number of newly added places.
  Future<int> discoverNearbyRealPlaces({
    double? latitude,
    double? longitude,
    String? fallbackCity,
    int radiusMeters = 6500,
  }) async {
    if (_isDiscoveringOsm) return 0;

    _isDiscoveringOsm = true;
    _lastOsmAddedCount = 0;
    notifyListeners();

    final targetLat = latitude ?? _userLocation.latitude;
    final targetLng = longitude ?? _userLocation.longitude;
    final cityLabel = fallbackCity ?? _userLocation.label;

    final discovered = await OsmDiscoveryService.fetchNearbyRealPlaces(
      latitude: targetLat,
      longitude: targetLng,
      fallbackCity: cityLabel,
      radiusMeters: radiusMeters,
    );

    int added = 0;
    final existingIds = _places.map((p) => p.id).toSet();

    for (final candidate in discovered) {
      if (existingIds.contains(candidate.id)) continue;

      // Avoid duplicating an existing place with the same name within 250m
      final duplicateNearby = _places.any((existing) {
        final sameName =
            existing.name.toLowerCase() == candidate.name.toLowerCase();
        final distKm = LocationService.distanceInKm(
          startLat: existing.latitude,
          startLng: existing.longitude,
          endLat: candidate.latitude,
          endLng: candidate.longitude,
        );
        return sameName && distKm < 0.25;
      });
      if (duplicateNearby) continue;

      _places.add(candidate);
      existingIds.add(candidate.id);
      added++;
    }

    _lastOsmAddedCount = added;
    _isDiscoveringOsm = false;
    if (added > 0) {
      await _persistPlaces();
    }
    notifyListeners();
    return added;
  }

  /// Distance in kilometers from the user's current position to [place].
  double distanceTo(SocietyPlace place) {
    return LocationService.distanceInKm(
      startLat: _userLocation.latitude,
      startLng: _userLocation.longitude,
      endLat: place.latitude,
      endLng: place.longitude,
    );
  }

  /// Combined score (wait time + estimated ~3 min/km urban travel time)
  /// used to find the nearest place with the lowest waiting time.
  double combinedScore(SocietyPlace place) {
    final km = distanceTo(place);
    return place.calculatedWaitMinutes + (km * 3.0);
  }

  /// Returns the single best (nearest + lowest waiting time) place.
  SocietyPlace? getBestPlace({
    PlaceCategory? category,
    CrowdStatus? crowdStatus,
    String? governorate,
    String searchQuery = '',
  }) {
    final filtered = getFilteredPlaces(
      category: category,
      crowdStatus: crowdStatus,
      governorate: governorate,
      searchQuery: searchQuery,
      sortMode: PlaceSortMode.bestRecommended,
    );
    if (filtered.isEmpty) return null;
    return filtered.first;
  }

  /// Filters establishments across all Tunisia by governorate, category, crowd color & search.
  List<SocietyPlace> getFilteredPlaces({
    String searchQuery = '',
    PlaceCategory? category,
    CrowdStatus? crowdStatus,
    String? governorate,
    PlaceSortMode sortMode = PlaceSortMode.bestRecommended,
  }) {
    final query = searchQuery.trim().toLowerCase();
    final govFilter = governorate?.trim().toLowerCase();

    final list = _places.where((place) {
      if (govFilter != null &&
          govFilter.isNotEmpty &&
          place.city.toLowerCase() != govFilter) {
        return false;
      }
      if (category != null && place.category != category) {
        return false;
      }
      if (crowdStatus != null && place.crowdStatus != crowdStatus) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = place.name.toLowerCase().contains(query);
        final matchesCity = place.city.toLowerCase().contains(query);
        final matchesAddress = place.address.toLowerCase().contains(query);
        final matchesCategory =
            place.category.label.toLowerCase().contains(query) ||
                place.category.searchKeywords
                    .any((kw) => kw.contains(query) || query.contains(kw));
        if (!matchesName &&
            !matchesCity &&
            !matchesAddress &&
            !matchesCategory) {
          return false;
        }
      }
      return true;
    }).toList();

    list.sort((a, b) {
      switch (sortMode) {
        case PlaceSortMode.bestRecommended:
          final scoreCmp = combinedScore(a).compareTo(combinedScore(b));
          if (scoreCmp != 0) return scoreCmp;
          return a.calculatedWaitMinutes.compareTo(b.calculatedWaitMinutes);
        case PlaceSortMode.lowestWait:
          final waitCmp =
              a.calculatedWaitMinutes.compareTo(b.calculatedWaitMinutes);
          if (waitCmp != 0) return waitCmp;
          return distanceTo(a).compareTo(distanceTo(b));
        case PlaceSortMode.nearestDistance:
          final distCmp = distanceTo(a).compareTo(distanceTo(b));
          if (distCmp != 0) return distCmp;
          return a.calculatedWaitMinutes.compareTo(b.calculatedWaitMinutes);
      }
    });

    return list;
  }

  SocietyPlace? getPlaceById(String id) {
    for (final place in _places) {
      if (place.id == id) return place;
    }
    return null;
  }

  /// Society interface action: updates guichet count, last ticket, and/or processing ticket.
  Future<void> updateSocietyQueue({
    required String placeId,
    int? guichetCount,
    int? lastTicketNumber,
    int? currentTicketNumber,
  }) async {
    final index = _places.indexWhere((p) => p.id == placeId);
    if (index == -1) return;

    final existing = _places[index];
    final safeGuichets = max(1, guichetCount ?? existing.guichetCount);
    final safeLast = max(0, lastTicketNumber ?? existing.lastTicketNumber);
    var safeCurrent =
        max(0, currentTicketNumber ?? existing.currentTicketNumber);
    if (safeCurrent > safeLast) {
      safeCurrent = safeLast;
    }

    final updated = existing.copyWith(
      guichetCount: safeGuichets,
      lastTicketNumber: safeLast,
      currentTicketNumber: safeCurrent,
    );

    _places[index] = updated.recalculated(DateTime.now());
    await _persistPlaces();
    notifyListeners();
  }

  /// Registers a brand-new establishment in any of Tunisia's 24 governorates.
  Future<SocietyPlace> addSocietyPlace({
    required String name,
    required String city,
    required String address,
    required PlaceCategory category,
    required int guichetCount,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now();
    final rng = Random();
    final govLocation = TunisiaDirectory.governorateByName(city);
    final lat = latitude ?? (govLocation.latitude + (rng.nextDouble() - 0.5) * 0.014);
    final lng = longitude ?? (govLocation.longitude + (rng.nextDouble() - 0.5) * 0.014);

    final newPlace = SocietyPlace(
      id: 'soc_${now.millisecondsSinceEpoch}',
      name: name.trim(),
      city: city.trim().isEmpty ? 'Tunis' : city.trim(),
      address: address.trim().isEmpty ? city.trim() : address.trim(),
      category: category,
      latitude: lat,
      longitude: lng,
      guichetCount: max(1, guichetCount),
      lastTicketNumber: 0,
      currentTicketNumber: 0,
      calculatedWaitMinutes: 0,
      lastCalculatedAt: now,
    );

    _places.insert(0, newPlace);
    await _persistPlaces();
    notifyListeners();
    return newPlace;
  }

  void setFocusedMapPlace(String? placeId) {
    _focusedMapPlaceId = placeId;
    notifyListeners();
  }

  void clearFocusedMapPlace() {
    _focusedMapPlaceId = null;
  }

  Future<void> _persistPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_places.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKeyPlaces, encoded);
    } catch (_) {
      // Ignore storage errors on restricted environments
    }
  }

  @override
  void dispose() {
    _periodicRecalcTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
