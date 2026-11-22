import 'package:flutter/material.dart';
import '../models/society_place.dart';
import '../theme/app_theme.dart';
import 'fluid_motion.dart';

class ServiceCard extends StatelessWidget {
  final SocietyPlace place;
  final double distanceKm;
  final VoidCallback onTap;
  final bool isRecommended;

  const ServiceCard({
    super.key,
    required this.place,
    required this.distanceKm,
    required this.onTap,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = place.crowdStatus;
    final filledSegments = place.meterSegments;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressScale(
        onTap: onTap,
        pressedScale: 0.982,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRecommended
                  ? AppColors.notCrowdedMain.withAlpha(85)
                  : AppColors.borderLight,
              width: isRecommended ? 1.2 : 1,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Soft-tinted category squircle (matching prototype)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      place.category.icon,
                      color: status.color,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 13),
                  // Place name & location distance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${place.city}  ·  ${distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Crowd status pill badge (Red / Yellow / Green)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
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
                        const SizedBox(width: 5),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: status.textColor,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Subtle hairline rule
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderLight,
              ),
              const SizedBox(height: 12),
              // 5-segment animated crowd bar + Wait time + Updated ago
              Row(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      final active = index < filledSegments;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        width: 14,
                        height: 5,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? status.color
                              : AppColors.inactiveSegment,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Wait ',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedCountText(
                    text: '${place.calculatedWaitMinutes} min',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    place.updatedAgoText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              // Quiet, breathable queue metadata line (no heavy nested grey box)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InlineMeta(
                    text: '${place.guichetCount} guichets',
                  ),
                  const _MetaSeparator(),
                  _InlineMeta(
                    text: 'Serving #${place.currentTicketNumber}',
                    strong: true,
                  ),
                  const _MetaSeparator(),
                  _InlineMeta(
                    text: 'Last #${place.lastTicketNumber}',
                  ),
                  const _MetaSeparator(),
                  _InlineMeta(
                    text: '${place.waitingPeople} waiting',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final String text;
  final bool strong;

  const _InlineMeta({
    required this.text,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
        color: strong ? AppColors.textPrimary : AppColors.textSecondary,
        fontFeatures: AppTheme.tabularFigures,
      ),
    );
  }
}

class _MetaSeparator extends StatelessWidget {
  const _MetaSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: AppColors.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}
