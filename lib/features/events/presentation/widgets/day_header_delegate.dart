import 'package:colette/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// En-tête de jour épinglé en haut de son groupe.
///
/// Reçoit ses couleurs résolues par le parent : le `build` d'un
/// `SliverPersistentHeaderDelegate` perd sa dépendance au `Theme` quand la
/// page est ré-attachée (ouverture d'une feuille modale), donc un changement
/// de thème doit passer par [shouldRebuild].
class DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  const DayHeaderDelegate(
    this.label, {
    required this.background,
    required this.textStyle,
  });

  final String label;
  final Color background;
  final TextStyle textStyle;

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
          child: Text(label, style: textStyle),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label ||
      oldDelegate.background != background ||
      oldDelegate.textStyle != textStyle;
}
