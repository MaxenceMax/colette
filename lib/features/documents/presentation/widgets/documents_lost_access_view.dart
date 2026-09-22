import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

/// Bookmark périmé ou dossier supprimé : invite à re-choisir le dossier.
class DocumentsLostAccessView extends ConsumerWidget {
  const DocumentsLostAccessView({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final result = await ref.read(documentsRootProvider.notifier).pick();
    if (!context.mounted) return;
    final picked = result.getOrElse((_) => false);
    if (picked) {
      context.go(AppRoutes.todayDocuments);
      return;
    }
    if (result case Left(:final value)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage(value, s))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return EmptyState(
      icon: Icons.folder_off_outlined,
      message: s.documentsLostAccessBody,
      action: FilledButton.icon(
        onPressed: () => _pick(context, ref),
        icon: const Icon(Icons.folder_open_outlined),
        label: Text(s.documentsCardPick),
      ),
    );
  }
}
