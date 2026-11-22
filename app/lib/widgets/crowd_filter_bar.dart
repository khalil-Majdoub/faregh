import 'package:flutter/material.dart';
import '../models/society_place.dart';
import '../theme/app_theme.dart';
import 'fluid_motion.dart';

class CategoryFilterRow extends StatelessWidget {
  final PlaceCategory? selectedCategory;
  final ValueChanged<PlaceCategory?> onSelected;
  final EdgeInsetsGeometry padding;

  const CategoryFilterRow({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        children: [
          _CategoryChip(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () => onSelected(null),
          ),
          ...PlaceCategory.values.map((category) {
            return _CategoryChip(
              label: category.label,
              isSelected: selectedCategory == category,
              onTap: () => onSelected(
                selectedCategory == category ? null : category,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressScale(
        onTap: onTap,
        pressedScale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navyDark : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.navyDark : AppColors.borderLight,
            ),
            boxShadow: isSelected ? const [] : AppTheme.softShadow,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CrowdStatusFilterRow extends StatelessWidget {
  final CrowdStatus? selectedStatus;
  final ValueChanged<CrowdStatus?> onSelected;
  final EdgeInsetsGeometry padding;

  const CrowdStatusFilterRow({
    super.key,
    required this.selectedStatus,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 33,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        children: [
          _StatusChip(
            label: 'All levels',
            dotColor: AppColors.navyDark,
            activeBg: AppColors.navyDark,
            activeText: Colors.white,
            isSelected: selectedStatus == null,
            onTap: () => onSelected(null),
          ),
          _StatusChip(
            label: 'Not crowded (<20m)',
            dotColor: AppColors.notCrowdedMain,
            activeBg: AppColors.notCrowdedBg,
            activeText: AppColors.notCrowdedText,
            isSelected: selectedStatus == CrowdStatus.notCrowded,
            onTap: () => onSelected(
              selectedStatus == CrowdStatus.notCrowded
                  ? null
                  : CrowdStatus.notCrowded,
            ),
          ),
          _StatusChip(
            label: 'Moderate (20–39m)',
            dotColor: AppColors.moderateMain,
            activeBg: AppColors.moderateBg,
            activeText: AppColors.moderateText,
            isSelected: selectedStatus == CrowdStatus.moderate,
            onTap: () => onSelected(
              selectedStatus == CrowdStatus.moderate
                  ? null
                  : CrowdStatus.moderate,
            ),
          ),
          _StatusChip(
            label: 'Crowded (40m+)',
            dotColor: AppColors.crowdedMain,
            activeBg: AppColors.crowdedBg,
            activeText: AppColors.crowdedText,
            isSelected: selectedStatus == CrowdStatus.crowded,
            onTap: () => onSelected(
              selectedStatus == CrowdStatus.crowded
                  ? null
                  : CrowdStatus.crowded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color dotColor;
  final Color activeBg;
  final Color activeText;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.dotColor,
    required this.activeBg,
    required this.activeText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressScale(
        onTap: onTap,
        pressedScale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? dotColor.withAlpha(110)
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected && activeBg == AppColors.navyDark
                      ? Colors.white
                      : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? activeText : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
