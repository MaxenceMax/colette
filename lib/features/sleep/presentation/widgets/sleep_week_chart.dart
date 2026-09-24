import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Frise 0 h → 24 h : une ligne par jour, nuits et siestes colorées.
class SleepWeekChart extends StatelessWidget {
  const SleepWeekChart({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<SleepDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _axisHours = [0, 6, 12, 18, 24];

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).coletteTextStyles.label
        .copyWith(color: context.appColor(AppColors.textSecondary));
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: AppSpacing.sm.horizontal,
          child: Row(
            children: [
              SizedBox(width: AppSize.huge.value),
              Expanded(
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    for (final hour in _axisHours) Text('$hour', style: muted),
                  ],
                ),
              ),
              SizedBox(width: AppSize.huge.value),
            ],
          ),
        ),
        for (var i = 0; i < days.length; i++)
          SleepWeekRow(
            day: days[i],
            selected: i == selectedIndex,
            onTap: () => onSelect(i),
          ),
      ],
    );
  }
}

/// Ligne d'un jour : libellé, segments, total.
class SleepWeekRow extends StatelessWidget {
  const SleepWeekRow({
    super.key,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final SleepDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final total = formatSleepDuration(day.total, s);
    return Semantics(
      label: s.sleepRowSemantics(formatLongDate(day.day), total),
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? context.appColor(AppColors.primaryContainer)
            : context.appColor(AppColors.transparent),
        borderRadius: AppRadius.sm.circular,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.sm.circular,
          child: Padding(
            padding: AppSpacing.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: AppSize.huge.value,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatShortWeekday(day.day),
                      style: styles.label,
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: AppSize.xs.value,
                    child: CustomPaint(
                      painter: SleepRowPainter(
                        day: day,
                        track: context.appColor(AppColors.surfaceContainer),
                        night: context.appColor(AppColors.sleepNight),
                        nap: context.appColor(AppColors.sleepNap),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppSize.huge.value,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(total, style: styles.label),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dessine la piste d'un jour et ses segments de sommeil.
class SleepRowPainter extends CustomPainter {
  SleepRowPainter({
    required this.day,
    required this.track,
    required this.night,
    required this.nap,
  });

  final SleepDay day;
  final Color track;
  final Color night;
  final Color nap;

  /// Position de [time] dans `[dayStart, dayEnd]`, entre 0 et 1.
  static double dayFraction(
    DateTime time,
    DateTime dayStart,
    DateTime dayEnd,
  ) =>
      time.difference(dayStart).inMinutes /
      dayEnd.difference(dayStart).inMinutes;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = AppRadius.xs.radius;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = track,
    );
    final dayEnd = DateTime(day.day.year, day.day.month, day.day.day + 1);
    for (final segment in day.segments) {
      final left = dayFraction(segment.start, day.day, dayEnd) * size.width;
      final right = dayFraction(segment.end, day.day, dayEnd) * size.width;
      final color = switch (segment.kind) {
        SleepKind.night => night,
        SleepKind.nap => nap,
      };
      canvas.drawRRect(
        RRect.fromLTRBR(left, 0, right, size.height, radius),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(SleepRowPainter oldDelegate) =>
      oldDelegate.day != day ||
      oldDelegate.track != track ||
      oldDelegate.night != night ||
      oldDelegate.nap != nap;
}
