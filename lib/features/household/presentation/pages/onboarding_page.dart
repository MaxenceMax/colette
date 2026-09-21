import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Premier écran sans foyer : créer ou rejoindre.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.lg.all,
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.child_friendly_outlined,
                size: AppSize.huge.value,
                color: context.appColor(AppColors.primary),
              ),
              AppSpacing.lg.verticalSpace,
              Text(
                s.onboardingTitle,
                style: styles.displayTitle,
                textAlign: .center,
              ),
              AppSpacing.sm.verticalSpace,
              Text(
                s.onboardingSubtitle,
                style: styles.body.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
                textAlign: .center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.push(AppRoutes.onboardingCreate),
                child: Text(s.onboardingCreate),
              ),
              AppSpacing.sm.verticalSpace,
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.onboardingJoin),
                child: Text(s.onboardingJoin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
