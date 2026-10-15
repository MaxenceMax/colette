import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Dents » de l'onglet Santé : dents en bouche et prochaines attendues.
class TeethCard extends ConsumerWidget {
  const TeethCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final teeth = ref.watch(teethProvider);
    final summary = ref.watch(teethSummaryProvider);
    final lines = switch ((teeth, summary)) {
      (AsyncError(:final error), _) => [failureMessage(error, s)],
      (_, final loaded?) => [
        loaded.inMouth == 0 ? s.teethNone : s.teethInMouth(loaded.inMouth),
        ?teethNextLabel(loaded.next, s),
      ],
      _ => const <String>[],
    };
    return Padding(
      padding: AppSpacing.md.top,
      child: ColetteCardSurface(
        onTap: () => context.push(AppRoutes.teeth),
        child: Row(
          spacing: AppSpacing.md.value,
          children: [
            Icon(Icons.mood, color: context.appColor(AppColors.primary)),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: AppSpacing.xxs.value,
                children: [
                  Text(s.teethTitle, style: styles.bodyMedium),
                  for (final line in lines)
                    Text(line, style: styles.small.copyWith(color: secondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: secondary),
          ],
        ),
      ),
    );
  }
}
