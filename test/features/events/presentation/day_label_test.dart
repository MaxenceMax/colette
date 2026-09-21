import 'package:colette/features/events/presentation/day_label.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 21, 14);
  late S s;

  setUpAll(() async => s = await S.delegate.load(const Locale('fr')));

  test('aujourd\'hui et hier', () {
    expect(dayLabel(DateTime(2026, 9, 21), now: now, s: s), 'Aujourd\'hui');
    expect(dayLabel(DateTime(2026, 9, 20), now: now, s: s), 'Hier');
  });

  test('les autres jours sont écrits en toutes lettres, capitalisés', () {
    expect(
      dayLabel(DateTime(2026, 9, 15), now: now, s: s),
      'Mardi 15 septembre',
    );
  });
}
