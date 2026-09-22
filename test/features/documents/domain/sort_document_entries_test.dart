import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/use_cases/sort_document_entries.dart';
import 'package:flutter_test/flutter_test.dart';

DocumentEntry entry(
  String name, {
  bool isDirectory = false,
  DateTime? modifiedAt,
}) => DocumentEntry(
  name: name,
  path: name,
  isDirectory: isDirectory,
  size: 0,
  modifiedAt: modifiedAt ?? DateTime(2026, 9, 1),
  downloadStatus: DownloadStatus.downloaded,
);

void main() {
  test('dossiers d\'abord, triés par nom sans tenir compte de la casse', () {
    final sorted = sortDocumentEntries([
      entry('zed.pdf'),
      entry('ordonnances', isDirectory: true),
      entry('Administratif', isDirectory: true),
      entry('carnet', isDirectory: true),
    ]);
    expect(sorted.map((e) => e.name).toList(), [
      'Administratif',
      'carnet',
      'ordonnances',
      'zed.pdf',
    ]);
  });

  test('fichiers par date décroissante, puis nom croissant', () {
    final sorted = sortDocumentEntries([
      entry('b.pdf', modifiedAt: DateTime(2026, 9, 10)),
      entry('a.pdf', modifiedAt: DateTime(2026, 9, 10)),
      entry('old.pdf', modifiedAt: DateTime(2026, 8, 1)),
      entry('new.pdf', modifiedAt: DateTime(2026, 9, 20)),
    ]);
    expect(sorted.map((e) => e.name).toList(), [
      'new.pdf',
      'a.pdf',
      'b.pdf',
      'old.pdf',
    ]);
  });

  test('ne modifie pas la liste d\'entrée', () {
    final input = [entry('b.pdf'), entry('a', isDirectory: true)];
    sortDocumentEntries(input);
    expect(input.first.name, 'b.pdf');
  });
}
