import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Échec d'écriture affiché dans une feuille Santé, annoncé à VoiceOver.
class SheetFailureText extends StatelessWidget {
  const SheetFailureText({super.key, required this.failure});

  final Object failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.md.top,
      child: Semantics(
        liveRegion: true,
        child: Text(
          failureMessage(failure, S.of(context)),
          style: Theme.of(context).coletteTextStyles.small
              .copyWith(color: context.appColor(AppColors.error)),
        ),
      ),
    );
  }
}
