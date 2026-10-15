import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/repositories/teeth_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Dent de test à partir de son numéro FDI ; échoue si le numéro est inconnu.
ToothId tooth(int number) => ToothId.tryParse(number)!;

/// Dent notée de test, horodatée au 14 octobre 2026 par `device-a`.
ToothRecord makeTooth(
  int number, {
  DateTime? eruptedAt,
  DateTime? lostAt,
  String? note,
}) => ToothRecord(
  toothId: tooth(number),
  eruptedAt: eruptedAt,
  lostAt: lostAt,
  note: note,
  updatedAt: DateTime(2026, 10, 14),
  updatedByDeviceId: 'device-a',
);

/// Dépôt simulé pour les tests de présentation.
class MockTeethRepository extends Mock implements TeethRepository {}
