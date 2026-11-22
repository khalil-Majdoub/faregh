import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/society_place.dart';
import '../../services/queue_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluid_motion.dart';
import 'alerts_screen.dart';
import 'place_detail_sheet.dart';
import 'profile_screen.dart';
import 'user_home_screen.dart';
import 'user_map_screen.dart';

class UserShellScreen extends StatefulWidget {
  const UserShellScreen({super.key});

  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  int _currentIndex = 0;

  void _openPlaceOnMap(SocietyPlace place) {
    context.read<QueueProvider>().setFocusedMapPlace(place.id);
    setState(() => _currentIndex = 1);
  }

  /// Signature elevated navy center button: calm "Where should I go?" quick finder.
  void _showSmartFinderModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _SmartFinderSheet(
        onShowOnMap: (place) {
          Navigator.of(ctx).pop();
          _openPlaceOnMap(place);
        },
        onShowDetails: (place) {
          Navigator.of(ctx).pop();
          showPlaceDetailSheet(
            context: context,
            place: place,
            onShowOnMap: () => _openPlaceOnMap(place),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      UserHomeScreen(
        onOpenPlaceOnMap: _openPlaceOnMap,
        onOpenAlerts: () => setState(() => _currentIndex = 2),
      ),
      const UserMapScreen(),
      AlertsScreen(onOpenPlaceOnMap: _openPlaceOnMap),
      const UserProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      // Keep every tab mounted (preserving Map tiles & scroll) with fluid fade transitions
      body: Stack(
        children: List.generate(pages.length, (i) {
          final active = i == _currentIndex;
          return IgnorePointer(
            ignoring: !active,
            child: AnimatedOpacity(
              opacity: active ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 210),
              curve: Curves.easeOutCubic,
              child: TickerMode(
                enabled: active,
                child: pages[i],
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: _PrototypeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onCenterTap: _showSmartFinderModal,
      ),
    );
  }
}

/// Custom Bottom Bar faithful to the uploaded prototype with tactile PressScale motion.
class _PrototypeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  const _PrototypeBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderLight, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0E0E1F33),
                  blurRadius: 18,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: 'Map',
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  const SizedBox(width: 66),
                  _NavItem(
                    icon: Icons.schedule_outlined,
                    activeIcon: Icons.schedule_rounded,
                    label: 'Live',
                    selected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
          // Signature elevated dark navy rounded-square center action
          Positioned(
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PressScale(
                  onTap: onCenterTap,
                  pressedScale: 0.92,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.navyDark,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3D0E1F33),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.near_me_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Fastest',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      pressedScale: 0.92,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey<bool>(selected),
                size: 23,
                color: selected ? AppColors.navyDark : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.navyDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartFinderSheet extends StatefulWidget {
  final ValueChanged<SocietyPlace> onShowOnMap;
  final ValueChanged<SocietyPlace> onShowDetails;

  const _SmartFinderSheet({
    required this.onShowOnMap,
    required this.onShowDetails,
  });

  @override
  State<_SmartFinderSheet> createState() => _SmartFinderSheetState();
}

class _SmartFinderSheetState extends State<_SmartFinderSheet> {
  PlaceCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    final best = queue.getBestPlace(category: _selectedCategory);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 18),
            const Text(
              'Where should I go?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pick a service and Feregh finds the closest branch with the shortest line.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FinderPill(
                  label: 'Anything',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...PlaceCategory.values.map((cat) {
                  return _FinderPill(
                    label: cat.label,
                    selected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  );
                }),
              ],
            ),
            const SizedBox(height: 18),
            if (best != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Container(
                  key: ValueKey<String>(best.id),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: best.crowdStatus.color.withAlpha(80),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: best.crowdStatus.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              best.category.icon,
                              color: best.crowdStatus.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  best.name,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${queue.distanceTo(best).toStringAsFixed(1)} km · ${best.guichetCount} guichets · ${best.waitingPeople} waiting',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: best.crowdStatus.backgroundColor,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              '${best.calculatedWaitMinutes} min',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: best.crowdStatus.textColor,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => widget.onShowOnMap(best),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(
                                  color: AppColors.borderLight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'See on map',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => widget.onShowDetails(best),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Queue details'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FinderPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FinderPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      pressedScale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyDark : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.navyDark : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
