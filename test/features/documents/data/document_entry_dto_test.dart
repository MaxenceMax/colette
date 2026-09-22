import 'package:colette/features/documents/data/dtos/document_entry_dto.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final modifiedAt = DateTime.utc(2026, 9, 22, 12, 30);

  Map<Object?, Object?> map({String status = 'downloaded'}) => {
    'name': 'ordonnance.pdf',
    'path': 'Ordonnances/ordonnance.pdf',
    'isDirectory': false,
    'size': 1234,
    'modifiedAt': modifiedAt.millisecondsSinceEpoch,
    'downloadStatus': status,
  };

  test('fromMap mappe tous les champs', () {
    final entry = DocumentEntryDto.fromMap(map());
    expect(entry.name, 'ordonnance.pdf');
    expect(entry.path, 'Ordonnances/ordonnance.pdf');
    expect(entry.isDirectory, isFalse);
    expect(entry.size, 1234);
    expect(entry.modifiedAt.toUtc(), modifiedAt);
    expect(entry.modifiedAt.isUtc, isFalse);
    expect(entry.downloadStatus, DownloadStatus.downloaded);
  });

  test('fromMap accepte modifiedAt et size en double', () {
    final map = {
      'name': 'ordonnance.pdf',
      'path': 'Ordonnances/ordonnance.pdf',
      'isDirectory': false,
      'size': 1000.0,
      'modifiedAt': 1000.0,
      'downloadStatus': 'downloaded',
    };
    final entry = DocumentEntryDto.fromMap(map);
    expect(entry.size, 1000);
    expect(entry.modifiedAt, DateTime.fromMillisecondsSinceEpoch(1000));
  });

  test('fromMap lit les trois statuts', () {
    expect(
      DocumentEntryDto.fromMap(map(status: 'downloading')).downloadStatus,
      DownloadStatus.downloading,
    );
    expect(
      DocumentEntryDto.fromMap(map(status: 'notDownloaded')).downloadStatus,
      DownloadStatus.notDownloaded,
    );
    expect(
      DocumentEntryDto.fromMap(map(status: 'autre')).downloadStatus,
      DownloadStatus.downloaded,
    );
  });

  test('fromMap applique des défauts sur les champs optionnels', () {
    final entry = DocumentEntryDto.fromMap(const {
      'name': 'Ordonnances',
      'path': 'Ordonnances',
      'isDirectory': true,
    });
    expect(entry.isDirectory, isTrue);
    expect(entry.size, 0);
    expect(entry.modifiedAt.millisecondsSinceEpoch, 0);
    expect(entry.downloadStatus, DownloadStatus.downloaded);
  });
}
