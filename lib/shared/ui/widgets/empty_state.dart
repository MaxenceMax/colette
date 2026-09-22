import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// État vide : icône et message centrés.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;

  /// Action optionnelle affichée sous le message.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final secondary = context.appColor(AppColors.textSecondary);
    return Center(
      child: Padding(
        padding: AppSpacing.xl.all,
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(icon, size: AppSize.xl.value, color: secondary),
            AppSpacing.md.verticalSpace,
            Text(
              message,
              textAlign: .center,
              style: Theme.of(context).coletteTextStyles.body
                  .copyWith(color: secondary),
            ),
            if (action case final action?) ...[
              AppSpacing.md.verticalSpace,
              action,
            ],
          ],
        ),
      ),
    );
  }
}
