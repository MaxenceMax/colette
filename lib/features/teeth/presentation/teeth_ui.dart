import 'package:colette/core/dates/time_format.dart';
import 'package:colette/features/teeth/domain/entities/teeth_summary.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/entities/tooth_status.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_tooth_status.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// « Incisive centrale ».
String toothKindLabel(ToothKind kind, S s) => switch (kind) {
  ToothKind.centralIncisor => s.toothKindCentralIncisor,
  ToothKind.lateralIncisor => s.toothKindLateralIncisor,
  ToothKind.canine => s.toothKindCanine,
  ToothKind.firstPremolar => s.toothKindFirstPremolar,
  ToothKind.secondPremolar => s.toothKindSecondPremolar,
  ToothKind.firstMolar => s.toothKindFirstMolar,
  ToothKind.secondMolar => s.toothKindSecondMolar,
  ToothKind.thirdMolar => s.toothKindThirdMolar,
};

/// « incisives centrales ».
String toothGroupLabel(ToothKind kind, S s) => switch (kind) {
  ToothKind.centralIncisor => s.toothGroupCentralIncisor,
  ToothKind.lateralIncisor => s.toothGroupLateralIncisor,
  ToothKind.canine => s.toothGroupCanine,
  ToothKind.firstPremolar => s.toothGroupFirstPremolar,
  ToothKind.secondPremolar => s.toothGroupSecondPremolar,
  ToothKind.firstMolar => s.toothGroupFirstMolar,
  ToothKind.secondMolar => s.toothGroupSecondMolar,
  ToothKind.thirdMolar => s.toothGroupThirdMolar,
};

/// « du haut » / « du bas ».
String toothArchLabel(ToothArch arch, S s) => switch (arch) {
  ToothArch.upper => s.toothArchUpper,
  ToothArch.lower => s.toothArchLower,
};

/// « Incisive centrale du haut, à droite ».
String toothName(ToothId id, S s) => s.toothName(
  toothKindLabel(id.kind, s),
  toothArchLabel(id.arch, s),
  switch (id.side) {
    ToothSide.right => s.toothSideRight,
    ToothSide.left => s.toothSideLeft,
  },
);

/// « 6-10 mois » ou « 6-7 ans ».
String ageRangeLabel(AgeRange range, S s) => switch (range.unit) {
  AgeUnit.months => s.toothAgeMonths(range.from, range.to),
  AgeUnit.years => s.toothAgeYears(range.from, range.to),
};

/// « incisives centrales du bas (6-10 mois) ».
String expectedGroupLabel(ExpectedTeethGroup group, S s) =>
    s.teethExpectedGroup(
      toothGroupLabel(group.kind, s),
      toothArchLabel(group.arch, s),
      ageRangeLabel(group.eruption, s),
    );

/// Repère d'âge affiché dans la fiche.
String toothReferenceText(ToothId id, S s) {
  final reference = toothReferenceOf(id);
  final eruption = ageRangeLabel(reference.eruption, s);
  return switch (reference.shedding) {
    null => s.toothReferenceEruption(eruption),
    final shedding => s.toothReferenceFull(
      eruption,
      ageRangeLabel(shedding, s),
    ),
  };
}

/// Libellé VoiceOver d'une dent du schéma.
String toothSemanticsLabel(ToothId id, ToothRecord? record, S s) {
  final name = toothName(id, s);
  return switch ((const ComputeToothStatus()(record), record)) {
    (ToothStatus.lost, ToothRecord(lostAt: final at?)) => s.toothSemanticsLost(
      name,
      formatShortDate(at),
    ),
    (ToothStatus.erupted, ToothRecord(eruptedAt: final at?)) =>
      s.toothSemanticsErupted(name, formatShortDate(at)),
    _ => s.toothSemanticsAbsent(name),
  };
}

/// Compteur de la page : « 3 sorties sur 20 », suivi des dents tombées.
String teethCounterLabel(
  Dentition dentition,
  Map<ToothId, ToothRecord> records,
  S s,
) {
  const status = ComputeToothStatus();
  final ids = ToothId.all(dentition);
  final statuses = [for (final id in ids) status(records[id])];
  final noted = statuses.where((st) => st != ToothStatus.absent).length;
  final lost = statuses.where((st) => st == ToothStatus.lost).length;
  final erupted = s.teethEruptedCount(noted, ids.length);
  return lost == 0
      ? erupted
      : s.teethCounterWithLost(erupted, s.teethLostCount(lost));
}

/// Ligne « Ensuite : … » de la carte ; `null` sans groupe attendu.
String? teethNextLabel(List<ExpectedTeethGroup> next, S s) => switch (next) {
  [] => null,
  [final first] => s.teethNextOne(expectedGroupLabel(first, s)),
  [final first, final second, ...] => s.teethNextTwo(
    expectedGroupLabel(first, s),
    expectedGroupLabel(second, s),
  ),
};
