import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';

/// Mapper des maps renvoyées par le canal `colette/documents` vers [DocumentEntry].
/// `modifiedAt` arrive en millisecondes UTC depuis epoch et est converti en heure locale.
abstract final class DocumentEntryDto {
  static DocumentEntry fromMap(Map<Object?, Object?> map) => DocumentEntry(
    name: map['name'] as String,
    path: map['path'] as String,
    isDirectory: map['isDirectory'] as bool? ?? false,
    size: (map['size'] as num?)?.toInt() ?? 0,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(
      (map['modifiedAt'] as num?)?.toInt() ?? 0,
      isUtc: true,
    ).toLocal(),
    downloadStatus: switch (map['downloadStatus']) {
      'downloading' => DownloadStatus.downloading,
      'notDownloaded' => DownloadStatus.notDownloaded,
      _ => DownloadStatus.downloaded,
    },
    downloadProgress: switch (map['downloadProgress']) {
      final num value => value.toDouble().clamp(0.0, 1.0),
      _ => null,
    },
  );
}
