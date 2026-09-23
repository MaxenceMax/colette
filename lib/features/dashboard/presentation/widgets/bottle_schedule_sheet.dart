import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la feuille « Prochaines 24 h ».
Future<void> showBottleScheduleSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const BottleScheduleSheet(),
    );

/// Timeline des biberons prévus sur les 24 prochaines heures.
class BottleScheduleSheet extends ConsumerWidget {
  const BottleScheduleSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottles = ref.watch(bottleScheduleProvider);
    if (bottles == null) return const SizedBox.shrink();
    final now = ref.watch(currentMinuteProvider);
    final entries = _entries(bottles, now);
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        const _HeaderSection(),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: AppSpacing.lg.all,
            itemCount: entries.length,
            itemBuilder: (context, index) => switch (entries[index]) {
              _DayEntry(:final tomorrow) => _DayHeader(tomorrow: tomorrow),
              _BottleEntry(:final bottle, :final isNext) => _BottleRow(
                bottle: bottle,
                now: now,
                isNext: isNext,
              ),
            },
          ),
        ),
      ],
    );
  }

  /// Aplatit les biberons en lignes, précédées d'un en-tête à chaque jour.
  static List<_Entry> _entries(List<ProjectedBottle> bottles, DateTime now) {
    final entries = <_Entry>[];
    DateTime? currentDay;
    for (final (index, bottle) in bottles.indexed) {
      // Un biberon en retard d'hier reste rangé sous « Aujourd'hui ».
      final day = (bottle.at.isAfter(now) ? bottle.at : now).dateOnly;
      if (day != currentDay) {
        entries.add(_DayEntry(tomorrow: day != now.dateOnly));
        currentDay = day;
      }
      entries.add(_BottleEntry(bottle: bottle, isNext: index == 0));
    }
    return entries;
  }
}

sealed class _Entry {
  const _Entry();
}

final class _DayEntry extends _Entry {
  const _DayEntry({required this.tomorrow});

  final bool tomorrow;
}

final class _BottleEntry extends _Entry {
  const _BottleEntry({required this.bottle, required this.isNext});

  final ProjectedBottle bottle;
  final bool isNext;
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return Padding(
      padding: AppSpacing.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xs.value,
        children: [
          Text(s.bottleScheduleTitle, style: styles.heading2),
          Text(
            s.bottleScheduleHint,
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.tomorrow});

  final bool tomorrow;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: AppSpacing.sm.vertical,
      child: Text(
        tomorrow ? s.dayTomorrow : s.dayToday,
        style: Theme.of(context).coletteTextStyles.heading3
            .copyWith(color: context.appColor(AppColors.textSecondary)),
      ),
    );
  }
}

/// Ligne « fourchette … quantité » ; le prochain biberon est surligné.
class _BottleRow extends StatelessWidget {
  const _BottleRow({
    required this.bottle,
    required this.now,
    required this.isNext,
  });

  final ProjectedBottle bottle;
  final DateTime now;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final status = isNext ? _status(s) : null;
    return Container(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isNext ? context.appColor(AppColors.primaryContainer) : null,
        borderRadius: AppRadius.sm.circular,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  s.bottleScheduleRange(
                    formatHourMinute(bottle.windowStart),
                    formatHourMinute(bottle.windowEnd),
                  ),
                  style: isNext ? styles.bodyMedium : styles.body,
                ),
                if (status case (final text, final color))
                  Text(
                    text,
                    style: styles.small.copyWith(
                      color: context.appColor(color),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            s.bottleMl(bottle.suggestedMl),
            style: styles.numberMedium.copyWith(
              color: context.appColor(
                isNext ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mention du prochain biberon : en retard, en cours, ou rien s'il est à venir.
  (String, AppColors)? _status(S s) {
    if (now.isAfter(bottle.windowEnd)) {
      return (
        s.nextBottleLate(now.difference(bottle.windowEnd).inMinutes),
        AppColors.warning,
      );
    }
    if (!now.isBefore(bottle.windowStart)) {
      return (s.nextBottleNow, AppColors.primary);
    }
    return null;
  }
}
