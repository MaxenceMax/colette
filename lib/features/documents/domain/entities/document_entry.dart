import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_entry.freezed.dart';

/// Entrée d'un dossier : sous-dossier ou fichier, avec son chemin relatif à la racine.
@freezed
abstract class DocumentEntry with _$DocumentEntry {
  const factory DocumentEntry({
    required String name,
    required String path,
    required bool isDirectory,
    required int size,
    required DateTime modifiedAt,
    required DownloadStatus downloadStatus,
  }) = _DocumentEntry;
}
