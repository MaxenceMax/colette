import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'id_generator.g.dart';

/// Générateur d'identifiants de documents.
abstract interface class IdGenerator {
  String newId();
}

/// UUID v4.
final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  @override
  String newId() => const Uuid().v4();
}

/// Renvoie toujours la même valeur, pour les tests.
final class FixedIdGenerator implements IdGenerator {
  const FixedIdGenerator(this.id);

  final String id;

  @override
  String newId() => id;
}

/// Générateur d'identifiants de l'app.
@riverpod
IdGenerator idGenerator(Ref ref) => const UuidIdGenerator();
