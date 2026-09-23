import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/health/presentation/providers/calendar_settings_controller.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/calendar_picker_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calendrier iOS où cet iPhone ajoute les RDV santé.
class CalendarSettingsSection extends ConsumerWidget {
  const CalendarSettingsSection({super.key});

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(calendarSettingsControllerProvider.notifier);
    final calendars = await controller.loadCalendars();
    if (calendars == null || !context.mounted) return;
    final picked = await showCalendarPickerSheet(context, calendars);
    if (picked != null) await controller.choose(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    ref.listen(calendarSettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final loading =
        ref.watch(calendarSettingsControllerProvider) is AsyncLoading;
    final choice = ref.watch(selectedCalendarProvider);
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.sm.value,
        children: [
          Text(
            choice == null
                ? s.calendarNotSynced
                : s.calendarSyncedTo(choice.title),
            style: styles.body.copyWith(
              color: context.appColor(
                choice == null ? AppColors.textSecondary : AppColors.onSurface,
              ),
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm.value,
            children: [
              TextButton.icon(
                onPressed: loading ? null : () => _choose(context, ref),
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  choice == null ? s.calendarChoose : s.calendarChange,
                ),
              ),
              if (choice != null)
                TextButton(
                  onPressed: () => ref
                      .read(calendarSettingsControllerProvider.notifier)
                      .clear(),
                  child: Text(s.calendarStop),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
