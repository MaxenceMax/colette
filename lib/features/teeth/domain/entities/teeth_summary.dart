import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';

/// Groupe de dents attendu : un type de dent sur une arcade, droite et gauche confondues.
typedef ExpectedTeethGroup = ({
  Dentition dentition,
  ToothArch arch,
  ToothKind kind,
  AgeRange eruption,
});

/// Résumé des dents pour la carte de l'onglet Santé.
final class TeethSummary {
  const TeethSummary({required this.inMouth, required this.next});

  /// Dents sorties et pas tombées, toutes dentitions confondues.
  final int inMouth;

  /// Au plus deux groupes, dans l'ordre habituel de sortie.
  final List<ExpectedTeethGroup> next;
}
