import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compteurs du jour : couches, pipis, cacas.
class DayCountersRow extends ConsumerWidget {
  const DayCountersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final counters = ref.watch(dayCountersProvider);
    return ColetteCardSurface(
      backgroundColor: AppColors.secondary,
      borderColor: AppColors.secondary,
      child: Row(
        children: [
          _Counter(value: counters.diapers, label: s.countersDiapers),
          _Counter(value: counters.pee, label: s.countersPee),
          _Counter(value: counters.poop, label: s.countersPoop),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    final color = context.appColor(AppColors.onSecondary);
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: styles.numberMedium.copyWith(color: color)),
          Text(label, style: styles.small.copyWith(color: color)),
        ],
      ),
    );
  }
}
