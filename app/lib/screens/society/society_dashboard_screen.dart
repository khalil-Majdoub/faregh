import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/society_place.dart';
import '../../services/auth_provider.dart';
import '../../services/queue_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fluid_motion.dart';

class SocietyDashboardScreen extends StatefulWidget {
  const SocietyDashboardScreen({super.key});

  @override
  State<SocietyDashboardScreen> createState() => _SocietyDashboardScreenState();
}

class _SocietyDashboardScreenState extends State<SocietyDashboardScreen> {
  String? _activePlaceId;

  Future<void> _showNumberInputDialog({
    required BuildContext context,
    required String title,
    required int initialValue,
    required int minValue,
    int? maxValue,
    required ValueChanged<int> onConfirm,
  }) async {
    final controller = TextEditingController(text: initialValue.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter a number',
              helperText: maxValue != null
                  ? 'Between $minValue and $maxValue'
                  : 'Minimum: $minValue',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null) return;
                var clamped = parsed < minValue ? minValue : parsed;
                if (maxValue != null && clamped > maxValue) {
                  clamped = maxValue;
                }
                Navigator.of(ctx).pop(clamped);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      onConfirm(result);
    }
  }

  Future<void> _confirmResetQueue(
    BuildContext context,
    QueueProvider queue,
    SocietyPlace place,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Start a fresh queue?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This resets both the current serving ticket and last issued ticket to #0 for ${place.name}.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crowdedMain,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset to #0'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await queue.updateSocietyQueue(
        placeId: place.id,
        lastTicketNumber: 0,
        currentTicketNumber: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final queue = context.watch<QueueProvider>();
    final user = auth.currentUser;

    final defaultId = user?.societyPlaceId ??
        (queue.places.isNotEmpty ? queue.places.first.id : null);
    final selectedId = _activePlaceId ?? defaultId;
    final place = selectedId != null ? queue.getPlaceById(selectedId) : null;

    if (place == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No establishment branch linked yet.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => auth.logout(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      );
    }

    final status = place.crowdStatus;
    final perGuichetText =
        place.peoplePerGuichet == place.peoplePerGuichet.roundToDouble()
            ? place.peoplePerGuichet.toStringAsFixed(0)
            : place.peoplePerGuichet.toStringAsFixed(1);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            // Header with Transparent Feregh Logo
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feregh Staff',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.35,
                        ),
                      ),
                      Text(
                        'Counter & ticket desk',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PressScale(
                  onTap: () => auth.logout(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Sign out',
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

            const SizedBox(height: 16),

            // Branch Selector Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppTheme.softShadow,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: place.id,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                  items: queue.places.map((item) {
                    return DropdownMenuItem<String>(
                      value: item.id,
                      child: Row(
                        children: [
                          Icon(
                            item.category.icon,
                            size: 18,
                            color: AppColors.navyDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${item.name} · ${item.category.label}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _activePlaceId = value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Calm Live Status Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PulsingDot(color: status.color, size: 7),
                      const SizedBox(width: 6),
                      const Text(
                        'Visible to citizens right now',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: status.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: status.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedCountText(
                        text: '${place.calculatedWaitMinutes}',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: status.color,
                          height: 1.0,
                          letterSpacing: -1.2,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'min wait',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: List.generate(5, (i) {
                      final active = i < place.meterSegments;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          height: 6.5,
                          margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: active
                                ? status.color
                                : AppColors.inactiveSegment,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 11),
                  Text(
                    '${place.waitingPeople} waiting (${place.lastTicketNumber} − ${place.currentTicketNumber}) across ${place.guichetCount} guichets  ·  $perGuichetText/guichet × 5 min',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Side-by-Side Tactile Live Ticket Controls (Serving Now vs Last Ticket)
            Row(
              children: [
                Expanded(
                  child: _TicketDeskCard(
                    label: 'Serving now',
                    value: '#${place.currentTicketNumber}',
                    accentColor: AppColors.accentBlue,
                    actionLabel: 'Call next',
                    onPrimaryTap:
                        place.currentTicketNumber < place.lastTicketNumber
                            ? () => queue.updateSocietyQueue(
                                  placeId: place.id,
                                  currentTicketNumber:
                                      place.currentTicketNumber + 1,
                                )
                            : null,
                    onDecrement: place.currentTicketNumber > 0
                        ? () => queue.updateSocietyQueue(
                              placeId: place.id,
                              currentTicketNumber:
                                  place.currentTicketNumber - 1,
                            )
                        : null,
                    onTapNumber: () => _showNumberInputDialog(
                      context: context,
                      title: 'Serving ticket number',
                      initialValue: place.currentTicketNumber,
                      minValue: 0,
                      maxValue: place.lastTicketNumber,
                      onConfirm: (val) => queue.updateSocietyQueue(
                        placeId: place.id,
                        currentTicketNumber: val,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TicketDeskCard(
                    label: 'Last ticket',
                    value: '#${place.lastTicketNumber}',
                    accentColor: AppColors.navyDark,
                    actionLabel: 'New ticket',
                    onPrimaryTap: () => queue.updateSocietyQueue(
                      placeId: place.id,
                      lastTicketNumber: place.lastTicketNumber + 1,
                    ),
                    onDecrement:
                        place.lastTicketNumber > place.currentTicketNumber
                            ? () => queue.updateSocietyQueue(
                                  placeId: place.id,
                                  lastTicketNumber: place.lastTicketNumber - 1,
                                )
                            : null,
                    onTapNumber: () => _showNumberInputDialog(
                      context: context,
                      title: 'Last issued ticket',
                      initialValue: place.lastTicketNumber,
                      minValue: place.currentTicketNumber,
                      onConfirm: (val) => queue.updateSocietyQueue(
                        placeId: place.id,
                        lastTicketNumber: val,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Open Guichets Horizontal Stepper Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.notCrowdedBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.desk_outlined,
                      color: AppColors.locationGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open guichets',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Active counters serving now',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SmallStepperButton(
                    icon: Icons.remove_rounded,
                    onTap: place.guichetCount > 1
                        ? () => queue.updateSocietyQueue(
                              placeId: place.id,
                              guichetCount: place.guichetCount - 1,
                            )
                        : null,
                  ),
                  PressScale(
                    onTap: () => _showNumberInputDialog(
                      context: context,
                      title: 'Open guichets',
                      initialValue: place.guichetCount,
                      minValue: 1,
                      onConfirm: (val) => queue.updateSocietyQueue(
                        placeId: place.id,
                        guichetCount: val,
                      ),
                    ),
                    child: SizedBox(
                      width: 44,
                      child: Center(
                        child: AnimatedCountText(
                          text: '${place.guichetCount}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _SmallStepperButton(
                    icon: Icons.add_rounded,
                    onTap: () => queue.updateSocietyQueue(
                      placeId: place.id,
                      guichetCount: place.guichetCount + 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Auto-refresh interval card (2 min / 5 min)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Auto-refresh cycle',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Next in ${queue.formattedCountdown}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentBlue,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CycleOption(
                            label: 'Every 2 min',
                            selected: queue.refreshIntervalMinutes == 2,
                            onTap: () => queue.setRefreshIntervalMinutes(2),
                          ),
                        ),
                        Expanded(
                          child: _CycleOption(
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

            const SizedBox(height: 16),

            // Bottom Action Row
            Row(
              children: [
                Expanded(
                  child: PressScale(
                    onTap: () {
                      queue.recalculateAllWaitTimes(automatic: false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Text(
                            'Updated ${place.name}: ${place.calculatedWaitMinutes} min wait',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Publish update',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PressScale(
                  onTap: () => _confirmResetQueue(context, queue, place),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.crowdedMain.withAlpha(110),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.crowdedText,
                      ),
                    ),
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

class _TicketDeskCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final String actionLabel;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onDecrement;
  final VoidCallback onTapNumber;

  const _TicketDeskCard({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.actionLabel,
    required this.onPrimaryTap,
    required this.onDecrement,
    required this.onTapNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (onDecrement != null)
                PressScale(
                  onTap: onDecrement,
                  pressedScale: 0.9,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Icon(
                      Icons.remove_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          PressScale(
            onTap: onTapNumber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCountText(
                  text: value,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
                const Text(
                  'Tap number to edit',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PressScale(
            onTap: onPrimaryTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: onPrimaryTap != null
                    ? accentColor
                    : AppColors.inactiveSegment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$actionLabel (+1)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onPrimaryTap != null
                        ? Colors.white
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _SmallStepperButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return PressScale(
      onTap: onTap,
      pressedScale: 0.9,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.navyDark : AppColors.inactiveSegment,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 19,
          color: enabled ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _CycleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CycleOption({
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
