import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../data/tunisia_places.dart';
import '../../models/society_place.dart';
import '../../services/queue_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/crowd_filter_bar.dart';
import '../../widgets/fluid_motion.dart';
import 'place_detail_sheet.dart';

class UserMapScreen extends StatefulWidget {
  const UserMapScreen({super.key});

  @override
  State<UserMapScreen> createState() => _UserMapScreenState();
}

class _UserMapScreenState extends State<UserMapScreen> {
  final MapController _mapController = MapController();
  PlaceCategory? _selectedCategory;
  CrowdStatus? _selectedCrowdStatus;
  String? _selectedGovernorate;
  String? _selectedPlaceId;

  void _moveCamera(double lat, double lng, {double zoom = 14.2}) {
    try {
      _mapController.move(LatLng(lat, lng), zoom);
    } catch (_) {
      // Map controller not attached yet on first build
    }
  }

  void _showTunisiaOverview() {
    setState(() {
      _selectedGovernorate = null;
      _selectedPlaceId = null;
    });
    _moveCamera(34.65, 9.65, zoom: 6.3);
  }

  void _showGovernoratePicker(BuildContext context, QueueProvider queue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jump to Governorate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Explore queues in any of Tunisia’s 24 governorates.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.public_rounded,
                      color: AppColors.accentBlue,
                    ),
                    title: const Text(
                      'All Tunisia (Overview)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: _selectedGovernorate == null
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.locationGreen,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showTunisiaOverview();
                    },
                  ),
                  const Divider(color: AppColors.borderLight),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: TunisiaDirectory.allGovernorates.length,
                      itemBuilder: (context, index) {
                        final gov = TunisiaDirectory.allGovernorates[index];
                        final selected = _selectedGovernorate == gov.label;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.location_on_outlined,
                            size: 19,
                            color: selected
                                ? AppColors.locationGreen
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            gov.label,
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.locationGreen,
                                )
                              : null,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            setState(() {
                              _selectedGovernorate = gov.label;
                              _selectedPlaceId = null;
                            });
                            queue.setCustomUserLocation(gov);
                            _moveCamera(gov.latitude, gov.longitude, zoom: 12.6);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();

    final focusedId = queue.focusedMapPlaceId;
    if (focusedId != null) {
      final target = queue.getPlaceById(focusedId);
      queue.clearFocusedMapPlace();
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedPlaceId = target.id;
            if (_selectedGovernorate != null &&
                _selectedGovernorate != target.city) {
              _selectedGovernorate = null;
            }
            if (_selectedCategory != null &&
                _selectedCategory != target.category) {
              _selectedCategory = null;
            }
            if (_selectedCrowdStatus != null &&
                _selectedCrowdStatus != target.crowdStatus) {
              _selectedCrowdStatus = null;
            }
          });
          _moveCamera(target.latitude, target.longitude, zoom: 14.8);
        });
      }
    }

    final filteredPlaces = queue.getFilteredPlaces(
      category: _selectedCategory,
      crowdStatus: _selectedCrowdStatus,
      governorate: _selectedGovernorate,
      sortMode: PlaceSortMode.bestRecommended,
    );

    final SocietyPlace? selectedPlace = _selectedPlaceId != null
        ? queue.getPlaceById(_selectedPlaceId!)
        : null;

    final userLoc = queue.userLocation;
    final bestPlace = filteredPlaces.isNotEmpty ? filteredPlaces.first : null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(userLoc.latitude, userLoc.longitude),
            initialZoom: 13.4,
            onTap: (_, __) {
              if (_selectedPlaceId != null) {
                setState(() => _selectedPlaceId = null);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'tn.feregh.app',
            ),
            MarkerLayer(
              markers: [
                // User's live position marker (breathing blue beacon)
                Marker(
                  point: LatLng(userLoc.latitude, userLoc.longitude),
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const PulsingDot(color: AppColors.accentBlue, size: 16),
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Colored Crowd Markers (Red / Yellow / Green)
                ...filteredPlaces.map((place) {
                  final isSelected = place.id == _selectedPlaceId;
                  final status = place.crowdStatus;

                  return Marker(
                    point: LatLng(place.latitude, place.longitude),
                    width: 96,
                    height: 64,
                    child: Center(
                      child: PressScale(
                        onTap: () {
                          setState(() => _selectedPlaceId = place.id);
                          _moveCamera(
                            place.latitude,
                            place.longitude,
                            zoom: 14.5,
                          );
                        },
                        pressedScale: 0.92,
                        child: AnimatedScale(
                          scale: isSelected ? 1.12 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: status.color,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: isSelected ? 2.5 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: status.color
                                          .withAlpha(isSelected ? 130 : 80),
                                      blurRadius: isSelected ? 12 : 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      place.category.icon,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${place.calculatedWaitMinutes}m',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontFeatures: AppTheme.tabularFigures,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: isSelected ? 10 : 8,
                                height: isSelected ? 10 : 8,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Floating Top Bar & Filters
        SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(245),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PressScale(
                          onTap: () => _showGovernoratePicker(context, queue),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _selectedGovernorate ?? 'All Tunisia',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                              Text(
                                '${filteredPlaces.length} places · auto ${queue.refreshIntervalMinutes}m',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (bestPlace != null)
                        PressScale(
                          onTap: () {
                            setState(() => _selectedPlaceId = bestPlace.id);
                            _moveCamera(
                              bestPlace.latitude,
                              bestPlace.longitude,
                              zoom: 14.8,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.notCrowdedBg,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Text(
                              'Fastest',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.notCrowdedText,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              CategoryFilterRow(
                selectedCategory: _selectedCategory,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onSelected: (cat) {
                  setState(() {
                    _selectedCategory = cat;
                    _selectedPlaceId = null;
                  });
                },
              ),
              const SizedBox(height: 8),
              CrowdStatusFilterRow(
                selectedStatus: _selectedCrowdStatus,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onSelected: (status) {
                  setState(() {
                    _selectedCrowdStatus = status;
                    _selectedPlaceId = null;
                  });
                },
              ),
            ],
          ),
        ),

        // Smoothly positioned Map Actions (Scan OSM Area, All Tunisia, GPS) + Legend
        AnimatedPositioned(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          right: 16,
          bottom: selectedPlace != null ? 242 : 106,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Live OpenStreetMap Scan for current viewport
              PressScale(
                onTap: queue.isDiscoveringOsm
                    ? null
                    : () async {
                        final center = _mapController.camera.center;
                        final added = await queue.discoverNearbyRealPlaces(
                          latitude: center.latitude,
                          longitude: center.longitude,
                          fallbackCity:
                              _selectedGovernorate ?? queue.userLocation.label,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            content: Text(
                              added > 0
                                  ? 'Found $added real places in this area'
                                  : 'All mapped places here are already displayed',
                            ),
                          ),
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (queue.isDiscoveringOsm)
                        const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentBlue,
                          ),
                        )
                      else
                        const Icon(
                          Icons.travel_explore_rounded,
                          size: 17,
                          color: AppColors.accentBlue,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        queue.isDiscoveringOsm ? 'Scanning…' : 'Scan area',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Zoom out to view All Tunisia
              PressScale(
                onTap: _showTunisiaOverview,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Tooltip(
                    message: 'View all Tunisia',
                    child: Icon(
                      Icons.public_rounded,
                      size: 20,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Recenter on user GPS
              PressScale(
                onTap: () async {
                  await queue.refreshUserLocation();
                  _moveCamera(
                    queue.userLocation.latitude,
                    queue.userLocation.longitude,
                    zoom: 13.6,
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Tooltip(
                    message: 'My location',
                    child: Icon(
                      Icons.my_location_rounded,
                      size: 20,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(245),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppTheme.softShadow,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendDot(color: AppColors.notCrowdedMain, text: '<20m'),
                    SizedBox(width: 9),
                    _LegendDot(color: AppColors.moderateMain, text: '20–39m'),
                    SizedBox(width: 9),
                    _LegendDot(color: AppColors.crowdedMain, text: '40m+'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Smooth Animated Bottom Selected Preview Card
        Positioned(
          left: 16,
          right: 16,
          bottom: 98,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 230),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: selectedPlace != null
                ? _MapPlacePreviewCard(
                    key: ValueKey<String>(selectedPlace.id),
                    place: selectedPlace,
                    distanceKm: queue.distanceTo(selectedPlace),
                    onClose: () => setState(() => _selectedPlaceId = null),
                    onOpenDetails: () => showPlaceDetailSheet(
                      context: context,
                      place: selectedPlace,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7.5,
          height: 7.5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFeatures: AppTheme.tabularFigures,
          ),
        ),
      ],
    );
  }
}

class _MapPlacePreviewCard extends StatelessWidget {
  final SocietyPlace place;
  final double distanceKm;
  final VoidCallback onClose;
  final VoidCallback onOpenDetails;

  const _MapPlacePreviewCard({
    super.key,
    required this.place,
    required this.distanceKm,
    required this.onClose,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final status = place.crowdStatus;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: status.backgroundColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  place.category.icon,
                  color: status.color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${distanceKm.toStringAsFixed(1)} km · ${place.guichetCount} guichets · #${place.currentTicketNumber} / #${place.lastTicketNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status.backgroundColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${status.shortLabel} · ${place.calculatedWaitMinutes} min',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: status.textColor,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PressScale(
                onTap: onOpenDetails,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navyDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
