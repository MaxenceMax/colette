import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/domain/use_cases/build_scan_file_name.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_write_controller.g.dart';

/// Ajout d'un document (scan ou import) dans un dossier.
@riverpod
class DocumentsWriteController extends _$DocumentsWriteController {
  @override
  FutureOr<void> build() {}

  Future<void> scan(String folderPath) => _run(folderPath, (repo) {
    final fileName = buildScanFileName(ref.read(clockProvider).now());
    return repo.scan(folderPath: folderPath, fileName: fileName);
  });

  Future<void> importFile(String folderPath) =>
      _run(folderPath, (repo) => repo.importFile(folderPath: folderPath));

  Future<void> _run(
    String folderPath,
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
      (_) {
        ref.invalidate(documentsFolderProvider(folderPath));
        return const AsyncData(null);
      },
    );
  }
}
