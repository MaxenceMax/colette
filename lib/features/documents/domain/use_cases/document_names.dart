import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/use_cases/parent_path.dart';
import 'package:fpdart/fpdart.dart';

/// Nom de fichier ou de dossier saisi, sans espaces autour. Refuse un nom
/// vide, contenant `/`, ou commençant par `.` (fichier masqué, `.`, `..`).
Either<Failure, String> validateEntryName(String raw) {
  final name = raw.trim();
  if (name.isEmpty || name.contains('/') || name.startsWith('.')) {
    return left(const ValidationFailure(ValidationReason.invalidDocumentName));
  }
  return right(name);
}

/// `facture.pdf` → `('facture', '.pdf')` ; sans extension → `(nom, '')`.
(String, String) splitExtension(String name) {
  final index = name.lastIndexOf('.');
  if (index <= 0 || index == name.length - 1) return (name, '');
  return (name.substring(0, index), name.substring(index));
}

/// Vrai si [source] peut être déplacé dans le dossier [destination] : ni
/// son dossier actuel, ni lui-même, ni l'un de ses descendants.
bool canMoveInto({required String source, required String destination}) =>
    destination != parentPath(source) &&
    destination != source &&
    !destination.startsWith('$source/');
