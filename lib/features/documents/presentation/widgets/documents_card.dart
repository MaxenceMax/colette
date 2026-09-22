import 'dart:async';

import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Documents » sur Aujourd'hui : choix du dossier iCloud ou accès à la liste.
class DocumentsCard extends ConsumerWidget {
  const DocumentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(documentsRootProvider)) {
        AsyncData(value: final root?) => _RootCard(root: root),
        AsyncLoading() => const _LoadingCard(),
        _ => const _PickCard(),
      };
}

/// Dossier choisi : titre, nom du dossier, chevron.
class _RootCard extends StatelessWidget {
  const _RootCard({required this.root});

  final DocumentRoot root;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return ColetteCardSurface(
      onTap: () => context.push(AppRoutes.todayDocuments),
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(
            Icons.folder_shared_outlined,
            color: context.appColor(AppColors.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(s.documentsCardTitle, style: styles.bodyMedium),
                Text(
                  root.name,
                  style: styles.small.copyWith(color: secondary),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: secondary),
        ],
      ),
    );
  }
}

/// Aucun dossier : invitation et bouton vers le sélecteur iOS.
class _PickCard extends ConsumerWidget {
  const _PickCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Row(
            spacing: AppSpacing.sm.value,
            children: [
              Icon(
                Icons.folder_shared_outlined,
                color: context.appColor(AppColors.primary),
              ),
              Expanded(
                child: Text(
                  s.documentsCardEmptyBody,
                  style: styles.body.copyWith(
                    color: context.appColor(AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () =>
                unawaited(ref.read(documentsRootProvider.notifier).pick()),
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(s.documentsCardPick),
          ),
        ],
      ),
    );
  }
}

/// Pendant la lecture du bookmark ou le sélecteur : indicateur discret.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => ColetteCardSurface(
    child: Row(
      spacing: AppSpacing.sm.value,
      children: [
        SizedBox.square(
          dimension: AppSize.xs.value,
          child: CircularProgressIndicator(strokeWidth: AppSpacing.xxs.value),
        ),
        Text(
          S.of(context).documentsCardTitle,
          style: Theme.of(context).coletteTextStyles.bodyMedium,
        ),
      ],
    ),
  );
}
