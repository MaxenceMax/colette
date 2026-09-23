import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Liste des calendriers modifiables ; renvoie celui choisi, ou `null`.
Future<DeviceCalendar?> showCalendarPickerSheet(
  BuildContext context,
  List<DeviceCalendar> calendars,
) => showModalBottomSheet<DeviceCalendar>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => CalendarPickerSheet(calendars: calendars),
);

/// Choix du calendrier des RDV santé.
class CalendarPickerSheet extends StatelessWidget {
  const CalendarPickerSheet({super.key, required this.calendars});

  final List<DeviceCalendar> calendars;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return Padding(
      padding: AppSpacing.lg.all,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.sm.value,
        children: [
          Text(s.calendarPickerTitle, style: styles.heading2),
          Text(
            s.calendarPickerHint,
            style: styles.small.copyWith(color: secondary),
          ),
          if (calendars.isEmpty)
            Text(s.calendarPickerEmpty, style: styles.body)
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: calendars.length,
                itemBuilder: (context, index) {
                  final calendar = calendars[index];
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: AppSize.xxs.value,
                      color: context.appColor(AppColors.primary),
                    ),
                    title: Text(calendar.title, style: styles.bodyMedium),
                    subtitle: Text(
                      calendar.source,
                      style: styles.small.copyWith(color: secondary),
                    ),
                    onTap: () => Navigator.of(context).pop(calendar),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
