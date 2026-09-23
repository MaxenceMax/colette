import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// Mock du repository documents, pour les tests qui montent l'app entière.
class MockDocumentsRepository extends Mock implements DocumentsRepository {}

/// Override qui répond [root] (par défaut aucun dossier) à `rootFolder()`.
Override documentsRepositoryOverride({DocumentRoot? root}) {
  final repo = MockDocumentsRepository();
  when(() => repo.rootFolder()).thenAnswer((_) async => right(root));
  return documentsRepositoryProvider.overrideWithValue(repo);
}
