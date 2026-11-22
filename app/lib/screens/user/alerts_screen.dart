import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/society_place.dart';
import '../../services/queue_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluid_motion.dart';
import 'place_detail_sheet.dart';

class AlertsScreen extends StatelessWidget {
  final ValueChanged<SocietyPlace> onOpenPlaceOnMap;

  const AlertsScreen({
    super.key,
    required this.onOpenPlaceOnMap,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
        children: [
          const Text(
            'Live updates',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Automatic wait recalculation and the fastest spot per service.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          // Automatic Timer Control Card (2 min or 5 min)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const PulsingDot(color: AppColors.locationGreen, size: 7),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Auto-refresh timer',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Next update in ${queue.formattedCountdown}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PressScale(
                      onTap: () =>
                          queue.recalculateAllWaitTimes(automatic: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 15,
                              color: AppColors.textPrimary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Refresh',
                              style: TextStyle(
                                fontSize: 12.5,
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
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _IntervalTab(
                          label: 'Every 2 min',
                          selected: queue.refreshIntervalMinutes == 2,
                          onTap: () => queue.setRefreshIntervalMinutes(2),
                        ),
                      ),
                      Expanded(
                        child: _IntervalTab(
                          label: 'Every 5 min',
                          selected: queue.refreshIntervalMinutes == 5,
                          onTap: () => queue.setRefreshIntervalMinutes(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const Text(
            'Fastest by category',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          ...PlaceCategory.values.map((category) {
            final best = queue.getBestPlace(category: category);
            if (best == null) return const SizedBox.shrink();
            final status = best.crowdStatus;
            final dist = queue.distanceTo(best);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PressScale(
                onTap: () => showPlaceDetailSheet(
                  context: context,
                  place: best,
                  onShowOnMap: () => onOpenPlaceOnMap(best),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: status.backgroundColor,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          category.icon,
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
                              category.label,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              best.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${dist.toStringAsFixed(1)} km · ${best.guichetCount} guichets · ${best.waitingPeople} waiting',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFeatures: AppTheme.tabularFigures,
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
                          color: status.backgroundColor,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${best.calculatedWaitMinutes} min',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: status.textColor,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 18),
          const Text(
            'Recent recalculations',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: queue.logs.take(6).map((log) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        log.wasAutomatic
                            ? Icons.autorenew_rounded
                            : Icons.touch_app_outlined,
                        size: 16,
                        color: log.wasAutomatic
                            ? AppColors.locationGreen
                            : AppColors.accentBlue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          log.wasAutomatic
                              ? 'Automatic refresh (${log.placesUpdated} places)'
                              : 'Manual refresh (${log.placesUpdated} places)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(log.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntervalTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IntervalTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected ? AppTheme.softShadow : const [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
