import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bandeau discret affiché quand l'appareil est hors ligne.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    if (online) return const SizedBox.shrink();
    return ColoredBox(
      color: context.appColor(AppColors.primaryContainer),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppSpacing.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            S.of(context).offlineBanner,
            textAlign: .center,
            style: Theme.of(context).coletteTextStyles.small
                .copyWith(color: context.appColor(AppColors.onSurface)),
          ),
        ),
      ),
    );
  }
}
