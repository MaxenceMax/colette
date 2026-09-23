import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/domain/use_cases/build_scan_file_name.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_write_controller.g.dart';

/// Ajout d'un document (scan ou import) dans [folderPath].
///
/// Famille par dossier : la page racine et une sous-page poussée observent
/// chacune leur propre instance, sans se déclencher mutuellement.
@riverpod
class DocumentsWriteController extends _$DocumentsWriteController {
  @override
  FutureOr<void> build(String folderPath) {}

  Future<void> scan() => _run((repo) {
    final fileName = buildScanFileName(ref.read(clockProvider).now());
    return repo.scan(folderPath: folderPath, fileName: fileName);
  });

  Future<void> importFile() =>
      _run((repo) => repo.importFile(folderPath: folderPath));

  Future<void> _run(
    Future<Either<Failure, String>> Function(DocumentsRepository repo) action,
  ) async {
    state = const AsyncLoading();
    final result = await action(ref.read(documentsRepositoryProvider));
    state = result.fold(
      (failure) => switch (failure) {
        DocumentsFailure(reason: DocumentsReason.cancelled) => const AsyncData(
          null,
        ),
        _ => AsyncError(failure, StackTrace.current),
      },
      // Pas d'invalidation : Swift force le relistage du flux du dossier
      // après chaque écriture réussie. Une invalidation créerait un second
      // abonnement concurrent.
      (_) => const AsyncData(null),
    );
  }
}
