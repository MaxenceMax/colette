import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/domain/entities/baby_age.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Date du jour et âge du bébé.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  String _ageText(BabyAge age, S s) => switch (age.unit) {
    BabyAgeUnit.days => s.ageDays(age.count),
    BabyAgeUnit.weeks => s.ageWeeks(age.count),
    BabyAgeUnit.months => s.ageMonths(age.count),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final today = ref.watch(todayProvider);
    final name = ref.watch(babyProfileProvider).value?.name;
    final age = ref.watch(babyAgeProvider);
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          formatLongDate(today),
          style: styles.small.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
        Text(
          name != null && age != null
              ? s.dashboardAge(name, _ageText(age, s))
              : s.appTitle,
          style: styles.heading1,
        ),
      ],
    );
  }
}
