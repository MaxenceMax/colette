import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/events/domain/entities/care_day_summary.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:flutter/material.dart';

/// Nom du jour et, à droite, son bilan : lait et biberons, couches, pipis.
///
/// Couleurs et style résolus par le parent (voir `DayHeaderDelegate`).
class DayHeaderContent extends StatelessWidget {
  const DayHeaderContent({
    super.key,
    required this.label,
    required this.summary,
    required this.textStyle,
    required this.feedingColor,
    required this.diaperColor,
  });

  final String label;
  final CareDaySummary? summary;
  final TextStyle textStyle;
  final Color feedingColor;
  final Color diaperColor;

  /// Part maximale de la largeur laissée au bilan : au-delà, il rétrécit.
  static const _maxSummaryShare = 0.7;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        spacing: AppSpacing.sm.value,
        children: [
          Expanded(
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ),
          if (summary case final summary? when !summary.isEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * _maxSummaryShare,
              ),
              child: FittedBox(
                fit: .scaleDown,
                alignment: .centerRight,
                child: _SummarySection(
                  summary: summary,
                  textStyle: textStyle,
                  feedingColor: feedingColor,
                  diaperColor: diaperColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.summary,
    required this.textStyle,
    required this.feedingColor,
    required this.diaperColor,
  });

  final CareDaySummary summary;
  final TextStyle textStyle;
  final Color feedingColor;
  final Color diaperColor;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final semantics = [
      if (summary.bottleCount > 0)
        s.daySummaryMilkSemantics(summary.bottleMl, summary.bottleCount),
      if (summary.diapers > 0) s.daySummaryDiapersSemantics(summary.diapers),
      if (summary.pee > 0) s.daySummaryPeeSemantics(summary.pee),
    ].join(', ');
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: .min,
        spacing: AppSpacing.md.value,
        children: [
          if (summary.bottleCount > 0)
            _SummaryItem(
              icon: Icons.local_drink_outlined,
              text: s.daySummaryMilk(summary.bottleMl, summary.bottleCount),
              color: feedingColor,
              textStyle: textStyle,
            ),
          if (summary.diapers > 0)
            _SummaryItem(
              icon: CareType.diaperChange.icon,
              text: '${summary.diapers}',
              color: diaperColor,
              textStyle: textStyle,
            ),
          if (summary.pee > 0)
            _SummaryItem(
              icon: CareType.pee.icon,
              text: '${summary.pee}',
              color: diaperColor,
              textStyle: textStyle,
            ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.text,
    required this.color,
    required this.textStyle,
  });

  final IconData icon;
  final String text;
  final Color color;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      spacing: AppSpacing.xs.value,
      children: [
        Icon(icon, size: AppSize.xs.value, color: color),
        Text(text, style: textStyle.copyWith(color: color)),
      ],
    );
  }
}
