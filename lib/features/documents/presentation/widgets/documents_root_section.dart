import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Réglage du dossier iCloud : nom, changer, oublier.
class DocumentsRootSection extends ConsumerWidget {
  const DocumentsRootSection({super.key});

  Future<void> _forget(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.settingsDocumentsForget),
        content: Text(s.settingsDocumentsForgetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.settingsDocumentsForget),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(documentsRootProvider.notifier).forget();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return switch (ref.watch(documentsRootProvider)) {
      AsyncData(value: final root?) => _RootRow(
        root: root,
        onChange: () => ref.read(documentsRootProvider.notifier).pick(),
        onForget: () => _forget(context, ref),
      ),
      AsyncLoading() => const LinearProgressIndicator(),
      _ => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.folder_shared_outlined),
        title: Text(s.settingsDocumentsNone),
        trailing: TextButton(
          onPressed: () => ref.read(documentsRootProvider.notifier).pick(),
          child: Text(s.documentsCardPick),
        ),
      ),
    };
  }
}

/// Dossier choisi : nom et actions.
class _RootRow extends StatelessWidget {
  const _RootRow({
    required this.root,
    required this.onChange,
    required this.onForget,
  });

  final DocumentRoot root;
  final VoidCallback onChange;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return Column(
      crossAxisAlignment: .start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_shared_outlined),
          title: Text(s.settingsDocumentsFolder),
          subtitle: Text(
            root.name,
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm.value,
          children: [
            TextButton(
              onPressed: onChange,
              child: Text(s.settingsDocumentsChange),
            ),
            TextButton(
              onPressed: onForget,
              child: Text(
                s.settingsDocumentsForget,
                style: styles.bodyMedium.copyWith(
                  color: context.appColor(AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
