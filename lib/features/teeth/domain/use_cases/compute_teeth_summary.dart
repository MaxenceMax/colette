import 'package:colette/features/teeth/domain/entities/teeth_summary.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/entities/tooth_status.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_tooth_status.dart';

/// Dents en bouche et prochains groupes attendus, sans lien avec l'âge de l'enfant.
class ComputeTeethSummary {
  const ComputeTeethSummary();

  static const maxGroups = 2;

  TeethSummary call(Map<ToothId, ToothRecord> records) {
    const status = ComputeToothStatus();
    bool isAbsent(ToothId id) => status(records[id]) == ToothStatus.absent;
    final inMouth = records.values
        .where((record) => status(record) == ToothStatus.erupted)
        .length;
    final primaryMissing = ToothId.primaryAll.where(isAbsent).toList();
    final candidates = primaryMissing.isNotEmpty
        ? primaryMissing
        : ToothId.permanentAll.where(isAbsent).toList();
    final groups = <ExpectedTeethGroup>{
      for (final id in candidates)
        (
          dentition: id.dentition,
          arch: id.arch,
          kind: id.kind,
          eruption: toothReferenceOf(id).eruption,
        ),
    }.toList()..sort(_byUsualOrder);
    return TeethSummary(
      inMouth: inMouth,
      next: groups.take(maxGroups).toList(),
    );
  }

  /// Début de fourchette, puis le bas avant le haut, puis du milieu vers le fond.
  static int _byUsualOrder(ExpectedTeethGroup a, ExpectedTeethGroup b) {
    final byAge = a.eruption.fromMonths.compareTo(b.eruption.fromMonths);
    if (byAge != 0) return byAge;
    final byArch = _archRank(a.arch).compareTo(_archRank(b.arch));
    if (byArch != 0) return byArch;
    return a.kind.index.compareTo(b.kind.index);
  }

  static int _archRank(ToothArch arch) => switch (arch) {
    ToothArch.lower => 0,
    ToothArch.upper => 1,
  };
}
