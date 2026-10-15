import 'package:colette/features/teeth/domain/entities/tooth_id.dart';

/// Unité d'une fourchette d'âge, gardée telle que dans la source.
enum AgeUnit { months, years }

/// Fourchette d'âge `[from, to]` dans l'unité de la source.
typedef AgeRange = ({int from, int to, AgeUnit unit});

/// Repères d'une dent : sortie, et chute pour une dent de lait.
typedef ToothReference = ({AgeRange eruption, AgeRange? shedding});

/// Comparaison des fourchettes quelle que soit leur unité.
extension AgeRangeX on AgeRange {
  /// Début de la fourchette en mois.
  int get fromMonths => switch (unit) {
    AgeUnit.months => from,
    AgeUnit.years => from * 12,
  };
}

/// Repères de [id].
///
/// Source : American Dental Association, *Primary Tooth Development* et
/// *Permanent Tooth Development* (2012), MouthHealthy, lus le 2026-10-14.
ToothReference toothReferenceOf(ToothId id) =>
    _schedule[(id.dentition, id.arch, id.kind)]!;

AgeRange _months(int from, int to) =>
    (from: from, to: to, unit: AgeUnit.months);

AgeRange _years(int from, int to) => (from: from, to: to, unit: AgeUnit.years);

final Map<(Dentition, ToothArch, ToothKind), ToothReference> _schedule = {
  // Dents de lait, haut.
  (Dentition.primary, ToothArch.upper, ToothKind.centralIncisor): (
    eruption: _months(8, 12),
    shedding: _years(6, 7),
  ),
  (Dentition.primary, ToothArch.upper, ToothKind.lateralIncisor): (
    eruption: _months(9, 13),
    shedding: _years(7, 8),
  ),
  (Dentition.primary, ToothArch.upper, ToothKind.canine): (
    eruption: _months(16, 22),
    shedding: _years(10, 12),
  ),
  (Dentition.primary, ToothArch.upper, ToothKind.firstMolar): (
    eruption: _months(13, 19),
    shedding: _years(9, 11),
  ),
  (Dentition.primary, ToothArch.upper, ToothKind.secondMolar): (
    eruption: _months(25, 33),
    shedding: _years(10, 12),
  ),
  // Dents de lait, bas.
  (Dentition.primary, ToothArch.lower, ToothKind.centralIncisor): (
    eruption: _months(6, 10),
    shedding: _years(6, 7),
  ),
  (Dentition.primary, ToothArch.lower, ToothKind.lateralIncisor): (
    eruption: _months(10, 16),
    shedding: _years(7, 8),
  ),
  (Dentition.primary, ToothArch.lower, ToothKind.canine): (
    eruption: _months(17, 23),
    shedding: _years(9, 12),
  ),
  (Dentition.primary, ToothArch.lower, ToothKind.firstMolar): (
    eruption: _months(14, 18),
    shedding: _years(9, 11),
  ),
  (Dentition.primary, ToothArch.lower, ToothKind.secondMolar): (
    eruption: _months(23, 31),
    shedding: _years(10, 12),
  ),
  // Dents définitives, haut.
  (Dentition.permanent, ToothArch.upper, ToothKind.centralIncisor): (
    eruption: _years(7, 8),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.lateralIncisor): (
    eruption: _years(8, 9),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.canine): (
    eruption: _years(11, 12),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.firstPremolar): (
    eruption: _years(10, 11),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.secondPremolar): (
    eruption: _years(10, 12),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.firstMolar): (
    eruption: _years(6, 7),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.secondMolar): (
    eruption: _years(12, 13),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.thirdMolar): (
    eruption: _years(17, 21),
    shedding: null,
  ),
  // Dents définitives, bas.
  (Dentition.permanent, ToothArch.lower, ToothKind.centralIncisor): (
    eruption: _years(6, 7),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.lateralIncisor): (
    eruption: _years(7, 8),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.canine): (
    eruption: _years(9, 10),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.firstPremolar): (
    eruption: _years(10, 12),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.secondPremolar): (
    eruption: _years(11, 12),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.firstMolar): (
    eruption: _years(6, 7),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.secondMolar): (
    eruption: _years(11, 13),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.thirdMolar): (
    eruption: _years(17, 21),
    shedding: null,
  ),
};
