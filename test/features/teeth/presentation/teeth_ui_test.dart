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
  });

  test('repères d\'âge', () {
    expect(
      toothReferenceText(tooth(51), s),
      'Sort en général vers 8-12 mois, tombe vers 6-7 ans.',
    );
    expect(toothReferenceText(tooth(46), s), 'Sort en général vers 6-7 ans.');
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
      teethCounterLabel(Dentition.permanent, const {}, s),
      '0 sortie sur 32',
    );
  });

  test('ligne « Ensuite » de la carte', () {
    expect(
      teethNextLabel(const ComputeTeethSummary()(const {}).next, s),
      'Ensuite : incisives centrales du bas (6-10 mois), '
      'puis incisives centrales du haut (8-12 mois)',
    );
    expect(teethNextLabel(const [], s), isNull);
  });
}
