import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// En-tête de jour épinglé en haut de son groupe.
class DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  const DayHeaderDelegate(this.label);

  final String label;

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
      color: context.appColor(AppColors.pageBackground),
      child: Padding(
        padding: AppSpacing.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Align(
          alignment: .centerLeft,
          child: Text(
            label,
            style: Theme.of(context).coletteTextStyles.label
                .copyWith(color: context.appColor(AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}
