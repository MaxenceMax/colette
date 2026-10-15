import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_teeth_summary.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  late S s;

  setUpAll(() async => s = await S.delegate.load(const Locale('fr')));

  test('nom complet d\'une dent', () {
    expect(toothName(tooth(51), s), 'Incisive centrale du haut, à droite');
    expect(toothName(tooth(36), s), 'Première molaire du bas, à gauche');
    expect(toothName(tooth(18), s), 'Dent de sagesse du haut, à droite');
    expect(toothName(tooth(53), s), 'Canine du haut, à droite');
    expect(toothName(tooth(25), s), 'Deuxième prémolaire du haut, à gauche');
  });

  test('repères d\'âge', () {
    expect(
      toothReferenceText(tooth(51), s),
      'Sortie habituelle : 8-12 mois. Chute habituelle : 6-7 ans.',
    );
    expect(toothReferenceText(tooth(46), s), 'Sortie habituelle : 6-7 ans.');
  });

  test('libellés VoiceOver', () {
    expect(
      toothSemanticsLabel(tooth(71), null, s),
      'Incisive centrale du bas, à gauche, pas encore sortie',
    );
    expect(
      toothSemanticsLabel(
        tooth(71),
        makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
        s,
      ),
      'Incisive centrale du bas, à gauche, sortie le 10 janv. 2027',
    );
    expect(
      toothSemanticsLabel(
        tooth(71),
        makeTooth(71, lostAt: DateTime(2033, 5, 2, 12)),
        s,
      ),
      'Incisive centrale du bas, à gauche, tombée le 2 mai 2033',
    );
  });

  test('compteur de la page', () {
    final day = DateTime(2027, 1, 10, 12);
    expect(
      teethCounterLabel(Dentition.primary, const {}, s),
      '0 sortie sur 20',
    );
    expect(
      teethCounterLabel(Dentition.primary, {
        tooth(71): makeTooth(71, eruptedAt: day),
      }, s),
      '1 sortie sur 20',
    );
    expect(
      teethCounterLabel(Dentition.primary, {
        tooth(71): makeTooth(71, eruptedAt: day),
        tooth(81): makeTooth(81, eruptedAt: day, lostAt: day),
      }, s),
      '2 sorties sur 20 · 1 tombée',
    );
    expect(
      teethCounterLabel(Dentition.primary, {
        tooth(71): makeTooth(71, eruptedAt: day, lostAt: day),
        tooth(81): makeTooth(81, eruptedAt: day, lostAt: day),
      }, s),
      '2 sorties sur 20 · 2 tombées',
    );
    expect(
      teethCounterLabel(Dentition.permanent, const {}, s),
      '0 sortie sur 32',
    );
  });

  test('ligne « Ensuite » de la carte', () {
    expect(
      teethNextLabel(const ComputeTeethSummary()(const {}).next, s),
      'Ensuite : incisives centrales du bas (6-10 mois), '
      'puis incisives centrales du haut (8-12 mois)',
    );
    expect(teethNextLabel(const [], s), isNull);
    expect(
      teethNextLabel(
        const ComputeTeethSummary()(const {}).next.take(1).toList(),
        s,
      ),
      'Ensuite : incisives centrales du bas (6-10 mois)',
    );
  });

  test('groupe attendu de la dentition définitive', () {
    final records = {
      for (final id in ToothId.primaryAll)
        id: makeTooth(id.value, eruptedAt: DateTime(2027, 1, 10, 12)),
    };
    expect(
      expectedGroupLabel(const ComputeTeethSummary()(records).next.first, s),
      'incisives centrales du bas (6-7 ans)',
    );
  });
}
