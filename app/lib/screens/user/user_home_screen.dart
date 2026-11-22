import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/tunisia_places.dart';
import '../../models/society_place.dart';
import '../../services/auth_provider.dart';
import '../../services/queue_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/crowd_filter_bar.dart';
import '../../widgets/fluid_motion.dart';
import '../../widgets/nearest_best_card.dart';
import '../../widgets/service_card.dart';
import 'place_detail_sheet.dart';

class UserHomeScreen extends StatefulWidget {
  final ValueChanged<SocietyPlace> onOpenPlaceOnMap;
  final VoidCallback onOpenAlerts;

  const UserHomeScreen({
    super.key,
    required this.onOpenPlaceOnMap,
    required this.onOpenAlerts,
  });

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  String _searchQuery = '';
  PlaceCategory? _selectedCategory;
  CrowdStatus? _selectedCrowdStatus;
  String? _selectedGovernorate;
  PlaceSortMode _sortMode = PlaceSortMode.bestRecommended;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showLocationPicker(BuildContext context, QueueProvider queue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.76;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
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
                    'Location & Governorate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Covers all 24 governorates of Tunisia + live OpenStreetMap discovery.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.notCrowdedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.locationGreen,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Use live GPS (All Tunisia)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      queue.userLocation.isLiveGps
                          ? 'Active (${queue.userLocation.latitude.toStringAsFixed(4)}, ${queue.userLocation.longitude.toStringAsFixed(4)})'
                          : 'Detect your current position',
                    ),
                    onTap: () {
                      setState(() => _selectedGovernorate = null);
                      Navigator.of(ctx).pop();
                      queue.refreshUserLocation();
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withAlpha(24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.travel_explore_rounded,
                        color: AppColors.accentBlue,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Scan live places nearby (OpenStreetMap)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Fetch extra real branches around ${queue.userLocation.label}',
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final added = await queue.discoverNearbyRealPlaces();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Text(
                            added > 0
                                ? 'Added $added real establishments near ${queue.userLocation.label}'
                                : 'All nearby OpenStreetMap places are already loaded',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(color: AppColors.borderLight),
                  Row(
                    children: [
                      const Text(
                        'All 24 Governorates',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedGovernorate != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedGovernorate = null);
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Show All Tunisia'),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: TunisiaDirectory.allGovernorates.length,
                      itemBuilder: (context, index) {
                        final loc = TunisiaDirectory.allGovernorates[index];
                        final selected =
                            _selectedGovernorate == loc.label ||
                                (_selectedGovernorate == null &&
                                    queue.userLocation.label == loc.label);
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
                            loc.label,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.locationGreen,
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            queue.setCustomUserLocation(loc);
                            setState(() => _selectedGovernorate = loc.label);
                            Navigator.of(ctx).pop();
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

  String _sortLabel(PlaceSortMode mode) {
    switch (mode) {
      case PlaceSortMode.bestRecommended:
        return 'Best match';
      case PlaceSortMode.lowestWait:
        return 'Shortest wait';
      case PlaceSortMode.nearestDistance:
        return 'Closest';
    }
  }

  void _cycleSortMode() {
    setState(() {
      const values = PlaceSortMode.values;
      _sortMode = values[(_sortMode.index + 1) % values.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final queue = context.watch<QueueProvider>();
    final firstName = auth.currentUser?.firstName ?? 'User';

    final filteredPlaces = queue.getFilteredPlaces(
      searchQuery: _searchQuery,
      category: _selectedCategory,
      crowdStatus: _selectedCrowdStatus,
      governorate: _selectedGovernorate,
      sortMode: _sortMode,
    );

    final bestPlace = queue.getBestPlace(
      category: _selectedCategory,
      crowdStatus: _selectedCrowdStatus,
      governorate: _selectedGovernorate,
      searchQuery: _searchQuery,
    );

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.navyDark,
        onRefresh: () async {
          queue.recalculateAllWaitTimes(automatic: false);
          await queue.refreshUserLocation();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Clean Header: Transparent Feregh Logo + Live Sync Pill + Bell
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Feregh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    // Subtle live periodic sync toggle (2m / 5m)
                    PressScale(
                      onTap: () {
                        final next =
                            queue.refreshIntervalMinutes == 2 ? 5 : 2;
                        queue.setRefreshIntervalMinutes(next);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            content: Text(
                              'Auto-refresh switched to every $next min',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const PulsingDot(
                              color: AppColors.locationGreen,
                              size: 6,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${queue.refreshIntervalMinutes}m · ${queue.formattedCountdown}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PressScale(
                      onTap: widget.onOpenAlerts,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textPrimary,
                          size: 21,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Warm Greeting (faithful to prototype)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aslema, $firstName 👋',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Win bech temchi lyoum?',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        PressScale(
                          onTap: () => _showLocationPicker(context, queue),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: AppColors.locationGreen,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                queue.userLocation.label,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.locationGreen,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: AppColors.locationGreen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Prototype-inspired Search Bar with animated focus state
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isSearchFocused
                          ? AppColors.navyDark.withAlpha(140)
                          : AppColors.borderLight,
                      width: _isSearchFocused ? 1.3 : 1,
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search an administration...',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14.5,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 21,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          IconButton(
                            tooltip: 'Change location',
                            icon: queue.isLoadingLocation
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.locationGreen,
                                    ),
                                  )
                                : const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.locationGreen,
                                    size: 21,
                                  ),
                            onPressed: () =>
                                _showLocationPicker(context, queue),
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Category Filter Pills
            SliverToBoxAdapter(
              child: CategoryFilterRow(
                selectedCategory: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // Crowd Status Filter Pills
            SliverToBoxAdapter(
              child: CrowdStatusFilterRow(
                selectedStatus: _selectedCrowdStatus,
                onSelected: (status) =>
                    setState(() => _selectedCrowdStatus = status),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // Clean Light-Surface "Fastest nearby" Spotlight Card
            if (bestPlace != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: NearestBestCard(
                    place: bestPlace,
                    distanceKm: queue.distanceTo(bestPlace),
                    onTapDetails: () => showPlaceDetailSheet(
                      context: context,
                      place: bestPlace,
                      onShowOnMap: () => widget.onOpenPlaceOnMap(bestPlace),
                    ),
                    onShowOnMap: () => widget.onOpenPlaceOnMap(bestPlace),
                  ),
                ),
              ),

            // "Nearby services" section header (matching prototype)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedGovernorate != null
                                ? 'Services in $_selectedGovernorate'
                                : 'Nearby services',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.35,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedGovernorate != null
                                ? '${filteredPlaces.length} places · tap location to view all Tunisia'
                                : '${filteredPlaces.length} places across all 24 governorates',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PressScale(
                      onTap: _cycleSortMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.swap_vert_rounded,
                              size: 15,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sortLabel(_sortMode),
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
                  ],
                ),
              ),
            ),

            // Filtered Services List
            if (filteredPlaces.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 42,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 42,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Nothing matches those filters',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedCategory = null;
                            _selectedCrowdStatus = null;
                            _selectedGovernorate = null;
                          });
                        },
                        child: const Text('Reset filters'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final place = filteredPlaces[index];
                      return ServiceCard(
                        place: place,
                        distanceKm: queue.distanceTo(place),
                        isRecommended: bestPlace?.id == place.id,
                        onTap: () => showPlaceDetailSheet(
                          context: context,
                          place: place,
                          onShowOnMap: () => widget.onOpenPlaceOnMap(place),
                        ),
                      );
                    },
                    childCount: filteredPlaces.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
