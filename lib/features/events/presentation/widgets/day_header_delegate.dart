import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/events/domain/entities/care_day_summary.dart';
import 'package:colette/features/events/presentation/widgets/day_header_content.dart';
import 'package:flutter/material.dart';

/// En-tête de jour épinglé en haut de son groupe, avec le bilan du jour.
///
/// Reçoit ses couleurs résolues par le parent : le `build` d'un
/// `SliverPersistentHeaderDelegate` perd sa dépendance au `Theme` quand la
/// page est ré-attachée (ouverture d'une feuille modale), donc un changement
/// de thème doit passer par [shouldRebuild].
class DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  const DayHeaderDelegate(
    this.label, {
    required this.summary,
    required this.background,
    required this.textStyle,
    required this.feedingColor,
    required this.diaperColor,
  });

  final String label;
  final CareDaySummary? summary;
  final Color background;
  final TextStyle textStyle;
  final Color feedingColor;
  final Color diaperColor;

  @override
  double get minExtent => AppSize.lg.value;

  @override
  double get maxExtent => AppSize.lg.value;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: background,
      child: Padding(
        padding: AppSpacing.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Align(
          alignment: .centerLeft,
          child: DayHeaderContent(
            label: label,
            summary: summary,
            textStyle: textStyle,
            feedingColor: feedingColor,
            diaperColor: diaperColor,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label ||
      oldDelegate.summary != summary ||
      oldDelegate.background != background ||
      oldDelegate.textStyle != textStyle ||
      oldDelegate.feedingColor != feedingColor ||
      oldDelegate.diaperColor != diaperColor;
}
