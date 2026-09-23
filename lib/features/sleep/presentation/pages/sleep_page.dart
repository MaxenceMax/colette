import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_days.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_day_details.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_form_sheet.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_week_chart.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Sommeil : frise des 7 derniers jours et détail du jour choisi.
class SleepPage extends ConsumerStatefulWidget {
  const SleepPage({super.key});

  @override
  ConsumerState<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends ConsumerState<SleepPage> {
  /// Jour sélectionné ; aujourd'hui (dernière ligne) par défaut.
  int _selected = sleepWeekDayCount - 1;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final weekSleeps = ref.watch(weekSleepsProvider);
    final days = ref.watch(sleepWeekProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.sleepPageTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSleepFormSheet(context),
        tooltip: s.sleepAddPast,
        child: const Icon(Icons.add),
      ),
      body: switch ((days, weekSleeps)) {
        (null, AsyncError()) => EmptyState(
          icon: Icons.error_outline,
          message: s.errorUnknown,
        ),
        (null, _) => const Center(child: CircularProgressIndicator()),
        (final days?, _) => ListView(
          padding: AppSpacing.md.all,
          children: [
            _SummarySection(days: days),
            AppSpacing.md.verticalSpace,
            ColetteCardSurface(
              child: SleepWeekChart(
                days: days,
                selectedIndex: _selected,
                onSelect: (index) => setState(() => _selected = index),
              ),
            ),
            AppSpacing.md.verticalSpace,
            SleepDayDetails(day: days[_selected]),
            AppSpacing.xxl.verticalSpace,
          ],
        ),
      },
    );
  }
}

/// Moyenne des jours précédents et repère OMS, au-dessus de la frise.
class _SummarySection extends ConsumerWidget {
  const _SummarySection({required this.days});

  final List<SleepDay> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final band = ref.watch(sleepAgeBandProvider);
    final average = averageOfPreviousDays(days);
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xs.value,
      children: [
        if (average != null)
          Text(
            s.sleepAverage(formatSleepDuration(average, s)),
            style: styles.bodyMedium,
          ),
        if (band != null)
          Text(
            s.sleepReference(band.minHours, band.maxHours),
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
