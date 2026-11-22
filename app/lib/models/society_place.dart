import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PlaceCategory {
  post,
  hospital,
  bank,
  municipality,
  utilities,
}

extension PlaceCategoryInfo on PlaceCategory {
  String get label {
    switch (this) {
      case PlaceCategory.post:
        return 'Post';
      case PlaceCategory.hospital:
        return 'Hospital';
      case PlaceCategory.bank:
        return 'Bank';
      case PlaceCategory.municipality:
        return 'Municipality';
      case PlaceCategory.utilities:
        return 'Utilities';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceCategory.post:
        return Icons.mail_outline_rounded;
      case PlaceCategory.hospital:
        return Icons.local_hospital_outlined;
      case PlaceCategory.bank:
        return Icons.account_balance_outlined;
      case PlaceCategory.municipality:
        return Icons.location_city_outlined;
      case PlaceCategory.utilities:
        return Icons.bolt_rounded;
    }
  }

  /// Search aliases so typing "poste", "healthcare", "banque", etc. matches.
  List<String> get searchKeywords {
    switch (this) {
      case PlaceCategory.post:
        return ['post', 'poste', 'la poste', 'bosta', 'mail'];
      case PlaceCategory.hospital:
        return ['hospital', 'hopital', 'healthcare', 'clinic', 'clinique', 'cnam', 'sbitar'];
      case PlaceCategory.bank:
        return ['bank', 'banque', 'biat', 'stb', 'bna', 'attijari'];
      case PlaceCategory.municipality:
        return ['municipality', 'municipalite', 'baladia', 'mairie'];
      case PlaceCategory.utilities:
        return ['utilities', 'steg', 'sonede', 'cnam', 'administration'];
    }
  }
}

enum CrowdStatus {
  notCrowded, // < 20 min (Green)
  moderate,   // 20 - 39 min (Yellow)
  crowded,    // >= 40 min (Red)
}

extension CrowdStatusStyle on CrowdStatus {
  String get label {
    switch (this) {
      case CrowdStatus.notCrowded:
        return 'NOT CROWDED';
      case CrowdStatus.moderate:
        return 'MODERATE';
      case CrowdStatus.crowded:
        return 'CROWDED';
    }
  }

  String get shortLabel {
    switch (this) {
      case CrowdStatus.notCrowded:
        return 'Not Crowded';
      case CrowdStatus.moderate:
        return 'Moderate';
      case CrowdStatus.crowded:
        return 'Crowded';
    }
  }

  Color get color {
    switch (this) {
      case CrowdStatus.notCrowded:
        return AppColors.notCrowdedMain;
      case CrowdStatus.moderate:
        return AppColors.moderateMain;
      case CrowdStatus.crowded:
        return AppColors.crowdedMain;
    }
  }

  Color get textColor {
    switch (this) {
      case CrowdStatus.notCrowded:
        return AppColors.notCrowdedText;
      case CrowdStatus.moderate:
        return AppColors.moderateText;
      case CrowdStatus.crowded:
        return AppColors.crowdedText;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CrowdStatus.notCrowded:
        return AppColors.notCrowdedBg;
      case CrowdStatus.moderate:
        return AppColors.moderateBg;
      case CrowdStatus.crowded:
        return AppColors.crowdedBg;
    }
  }
}

class SocietyPlace {
  /// Constant service time assumed per person (5 minutes).
  static const int minutesPerPerson = 5;

  final String id;
  final String name;
  final String city;
  final String address;
  final PlaceCategory category;
  final double latitude;
  final double longitude;

  /// Number of active counters (guichets) open at this society.
  final int guichetCount;

  /// Last ticket number taken by a client (e.g., 150).
  final int lastTicketNumber;

  /// Ticket number currently being treated at the guichets (e.g., 100).
  final int currentTicketNumber;

  /// Cached wait time computed by the periodic function (every 2 or 5 minutes).
  final int calculatedWaitMinutes;

  /// Timestamp of the last waiting-time calculation.
  final DateTime lastCalculatedAt;

  const SocietyPlace({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.guichetCount,
    required this.lastTicketNumber,
    required this.currentTicketNumber,
    required this.calculatedWaitMinutes,
    required this.lastCalculatedAt,
  });

  /// Step 1: People waiting = Last Ticket - Current Processing Ticket.
  /// Example: 150 - 100 = 50 people waiting.
  int get waitingPeople => max(0, lastTicketNumber - currentTicketNumber);

  /// Step 2: People per guichet = Waiting People / Active Guichets.
  /// Example: 50 / 5 = 10 people per guichet.
  double get peoplePerGuichet {
    if (guichetCount <= 0) return waitingPeople.toDouble();
    return waitingPeople / guichetCount;
  }

  /// Step 3: Waiting Time (minutes) = People per Guichet * 5 minutes.
  /// Example: 10 * 5 = 50 minutes.
  static int calculateWaitMinutes({
    required int lastTicket,
    required int currentTicket,
    required int guichets,
  }) {
    final waiting = max(0, lastTicket - currentTicket);
    final safeGuichets = max(1, guichets);
    final perGuichet = waiting / safeGuichets;
    return (perGuichet * minutesPerPerson).round();
  }

  /// Recomputes wait time from current live ticket & guichet values.
  int computeLiveWaitMinutes() {
    return calculateWaitMinutes(
      lastTicket: lastTicketNumber,
      currentTicket: currentTicketNumber,
      guichets: guichetCount,
    );
  }

  /// Crowd classification based on calculated wait time:
  /// - >= 40 min        -> Crowded (Red)
  /// - 20 to 39 min     -> Moderate (Yellow)
  /// - < 20 min (<= 19) -> Not Crowded (Green)
  static CrowdStatus statusForWaitMinutes(int waitMinutes) {
    if (waitMinutes >= 40) {
      return CrowdStatus.crowded;
    } else if (waitMinutes >= 20) {
      return CrowdStatus.moderate;
    } else {
      return CrowdStatus.notCrowded;
    }
  }

  CrowdStatus get crowdStatus => statusForWaitMinutes(calculatedWaitMinutes);

  /// Number of filled segments (0..5) for the prototype's 5-bar crowd meter.
  int get meterSegments {
    if (calculatedWaitMinutes >= 50) return 5;
    if (calculatedWaitMinutes >= 40) return 4;
    if (calculatedWaitMinutes >= 20) return 3;
    if (calculatedWaitMinutes >= 10) return 2;
    if (calculatedWaitMinutes > 0) return 1;
    return 0;
  }

  /// Human-readable "X min ago" label for when the wait time was calculated.
  String get updatedAgoText {
    final diff = DateTime.now().difference(lastCalculatedAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes == 1) return '1 min ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours}h ago';
  }

  SocietyPlace copyWith({
    String? name,
    String? city,
    String? address,
    PlaceCategory? category,
    double? latitude,
    double? longitude,
    int? guichetCount,
    int? lastTicketNumber,
    int? currentTicketNumber,
    int? calculatedWaitMinutes,
    DateTime? lastCalculatedAt,
  }) {
    return SocietyPlace(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      guichetCount: guichetCount ?? this.guichetCount,
      lastTicketNumber: lastTicketNumber ?? this.lastTicketNumber,
      currentTicketNumber: currentTicketNumber ?? this.currentTicketNumber,
      calculatedWaitMinutes:
          calculatedWaitMinutes ?? this.calculatedWaitMinutes,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
    );
  }

  /// Returns a fresh copy with recalculated waiting time and current timestamp.
  SocietyPlace recalculated(DateTime now) {
    return copyWith(
      calculatedWaitMinutes: computeLiveWaitMinutes(),
      lastCalculatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'category': category.name,
      'latitude': latitude,
      'longitude': longitude,
      'guichetCount': guichetCount,
      'lastTicketNumber': lastTicketNumber,
      'currentTicketNumber': currentTicketNumber,
      'calculatedWaitMinutes': calculatedWaitMinutes,
      'lastCalculatedAt': lastCalculatedAt.toIso8601String(),
    };
  }

  factory SocietyPlace.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String? ?? 'post';
    final parsedCategory = PlaceCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => PlaceCategory.post,
    );

    final guichets = (json['guichetCount'] as num?)?.toInt() ?? 3;
    final lastTicket = (json['lastTicketNumber'] as num?)?.toInt() ?? 0;
    final currentTicket = (json['currentTicketNumber'] as num?)?.toInt() ?? 0;

    return SocietyPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String? ?? 'Sousse',
      address: json['address'] as String? ?? '',
      category: parsedCategory,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      guichetCount: max(1, guichets),
      lastTicketNumber: lastTicket,
      currentTicketNumber: currentTicket,
      calculatedWaitMinutes:
          (json['calculatedWaitMinutes'] as num?)?.toInt() ??
              calculateWaitMinutes(
                lastTicket: lastTicket,
                currentTicket: currentTicket,
                guichets: guichets,
              ),
      lastCalculatedAt:
          DateTime.tryParse(json['lastCalculatedAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
