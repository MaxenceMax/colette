import 'package:colette/features/documents/domain/entities/document_entry.dart';

int _byName(DocumentEntry a, DocumentEntry b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

int _byDateDescThenName(DocumentEntry a, DocumentEntry b) {
  final byDate = b.modifiedAt.compareTo(a.modifiedAt);
  return byDate != 0 ? byDate : _byName(a, b);
}

/// Sous-dossiers d'abord (nom, insensible à la casse), puis fichiers
/// (date de modification décroissante, nom croissant à égalité).
List<DocumentEntry> sortDocumentEntries(List<DocumentEntry> entries) {
  final folders = entries.where((e) => e.isDirectory).toList()..sort(_byName);
  final files = entries.where((e) => !e.isDirectory).toList()
    ..sort(_byDateDescThenName);
  return [...folders, ...files];
}
