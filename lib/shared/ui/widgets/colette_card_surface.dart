import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Carte : fond `surface`, bordure `border`, rayon `AppRadius.lg`.
class ColetteCardSurface extends StatelessWidget {
  const ColetteCardSurface({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.radius = AppRadius.lg,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AppColors backgroundColor;
  final AppColors borderColor;
  final AppRadius radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? AppSpacing.md.all,
      child: child,
    );
    return Material(
      color: context.appColor(backgroundColor),
      shape: RoundedRectangleBorder(
        borderRadius: radius.circular,
        side: BorderSide(color: context.appColor(borderColor)),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
