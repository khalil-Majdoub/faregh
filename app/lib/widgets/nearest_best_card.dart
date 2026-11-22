import 'package:flutter/material.dart';
import '../models/society_place.dart';
import '../theme/app_theme.dart';
import 'fluid_motion.dart';

class NearestBestCard extends StatelessWidget {
  final SocietyPlace place;
  final double distanceKm;
  final VoidCallback onTapDetails;
  final VoidCallback onShowOnMap;

  const NearestBestCard({
    super.key,
    required this.place,
    required this.distanceKm,
    required this.onTapDetails,
    required this.onShowOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final status = place.crowdStatus;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: PressScale(
        onTap: onTapDetails,
        pressedScale: 0.985,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: status.color.withAlpha(70),
              width: 1.2,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PulsingDot(color: status.color, size: 7),
                  const SizedBox(width: 6),
                  Text(
                    'Fastest nearby',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: status.textColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${distanceKm.toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: status.color,
                      borderRadius: BorderRadius.circular(4),
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
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${place.guichetCount} guichets  ·  Serving #${place.currentTicketNumber}  ·  ${place.waitingPeople} waiting',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        AnimatedCountText(
                          text: '${place.calculatedWaitMinutes}',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: status.textColor,
                            height: 1.0,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'min',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: status.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: PressScale(
                      onTap: onShowOnMap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 16,
                              color: AppColors.textPrimary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'See on map',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressScale(
                      onTap: onTapDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.navyDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Queue details',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
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
