import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/society_place.dart';
import '../../services/queue_provider.dart';
import '../../theme/app_theme.dart';

void showPlaceDetailSheet({
  required BuildContext context,
  required SocietyPlace place,
  VoidCallback? onShowOnMap,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PlaceDetailContent(
      placeId: place.id,
      onShowOnMap: onShowOnMap,
    ),
  );
}

class _PlaceDetailContent extends StatelessWidget {
  final String placeId;
  final VoidCallback? onShowOnMap;

  const _PlaceDetailContent({
    required this.placeId,
    this.onShowOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    final place = queue.getPlaceById(placeId);
    if (place == null) return const SizedBox.shrink();

    final status = place.crowdStatus;
    final distanceKm = queue.distanceTo(place);
    final perGuichetText = place.peoplePerGuichet == place.peoplePerGuichet.roundToDouble()
        ? place.peoplePerGuichet.toStringAsFixed(0)
        : place.peoplePerGuichet.toStringAsFixed(1);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Header row
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: status.backgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    place.category.icon,
                    color: status.color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${place.address}  •  ${distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: status.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${status.label}  ·  Estimated wait: ${place.calculatedWaitMinutes} min',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: status.textColor,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ),
                  Text(
                    place.updatedAgoText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status.textColor.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Live Ticket Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Processing',
                    value: '#${place.currentTicketNumber}',
                    icon: Icons.play_circle_outline_rounded,
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Last Ticket',
                    value: '#${place.lastTicketNumber}',
                    icon: Icons.confirmation_number_outlined,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Guichets',
                    value: '${place.guichetCount}',
                    icon: Icons.desk_outlined,
                    color: AppColors.locationGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Transparent Formula Breakdown Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waiting Time Calculation',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FormulaRow(
                    step: '1. Waiting people',
                    detail:
                        '${place.lastTicketNumber} − ${place.currentTicketNumber} = ${place.waitingPeople} people',
                  ),
                  const SizedBox(height: 5),
                  _FormulaRow(
                    step: '2. Per guichet',
                    detail:
                        '${place.waitingPeople} ÷ ${place.guichetCount} guichets = $perGuichetText / guichet',
                  ),
                  const SizedBox(height: 5),
                  _FormulaRow(
                    step: '3. Total wait (×5 min)',
                    detail:
                        '$perGuichetText × ${SocietyPlace.minutesPerPerson} min = ${place.calculatedWaitMinutes} min',
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Action Buttons
            Row(
              children: [
                if (onShowOnMap != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onShowOnMap!();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyDark,
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text(
                        'Show on Map',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      queue.recalculateAllWaitTimes(automatic: false);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Recalculate Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  final String step;
  final String detail;
  final bool highlight;

  const _FormulaRow({
    required this.step,
    required this.detail,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          step,
          style: TextStyle(
            fontSize: 12.5,
            color: highlight ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          detail,
          style: TextStyle(
            fontSize: 12.5,
            color: highlight ? AppColors.navyDark : AppColors.textPrimary,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
