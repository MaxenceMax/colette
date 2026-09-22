import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bookmark périmé ou dossier supprimé : invite à re-choisir le dossier.
class DocumentsLostAccessView extends ConsumerWidget {
  const DocumentsLostAccessView({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final picked = await ref.read(documentsRootProvider.notifier).pick();
    if (picked && context.mounted) context.go(AppRoutes.todayDocuments);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final secondary = context.appColor(AppColors.textSecondary);
    return Center(
      child: Padding(
        padding: AppSpacing.xl.all,
        child: Column(
          mainAxisSize: .min,
          spacing: AppSpacing.md.value,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: AppSize.xl.value,
              color: secondary,
            ),
            Text(
              s.documentsLostAccessBody,
              textAlign: .center,
              style: Theme.of(context).coletteTextStyles.body
                  .copyWith(color: secondary),
            ),
            FilledButton.icon(
              onPressed: () => _pick(context, ref),
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(s.documentsCardPick),
            ),
          ],
        ),
      ),
    );
  }
}
