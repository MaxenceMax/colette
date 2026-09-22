import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Réglage du dossier iCloud : nom, changer, oublier.
class DocumentsRootSection extends ConsumerWidget {
  const DocumentsRootSection({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final result = await ref.read(documentsRootProvider.notifier).pick();
    if (!context.mounted) return;
    if (result case Left(:final value)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage(value, s))));
    }
  }

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
    if (!context.mounted) return;
    if (confirmed != true) return;
    final result = await ref.read(documentsRootProvider.notifier).forget();
    if (!context.mounted) return;
    if (result case Left(:final value)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage(value, s))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(documentsRootProvider)) {
        AsyncData(value: final root?) => _RootRow(
          root: root,
          onChange: () => _pick(context, ref),
          onForget: () => _forget(context, ref),
        ),
        AsyncLoading() => const LinearProgressIndicator(),
        _ => _NoRootRow(onPick: () => _pick(context, ref)),
      };
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
      spacing: AppSpacing.xs.value,
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

/// Aucun dossier choisi : message puis bouton pour en choisir un.
class _NoRootRow extends StatelessWidget {
  const _NoRootRow({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xs.value,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_shared_outlined),
          title: Text(s.settingsDocumentsNone),
        ),
        TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.folder_open_outlined),
          label: Text(s.documentsCardPick),
        ),
      ],
    );
  }
}
