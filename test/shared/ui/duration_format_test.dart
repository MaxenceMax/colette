import 'package:colette/l10n/generated/app_localizations_fr.dart';
import 'package:colette/shared/ui/duration_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final s = SFr();

  test('formate minutes, heures rondes et heures-minutes', () {
    expect(formatDuration(const Duration(minutes: 42), s), '42 min');
    expect(formatDuration(const Duration(hours: 2), s), '2 h');
    expect(formatDuration(const Duration(hours: 1, minutes: 5), s), '1 h 05');
  });

  test('borne une durée négative à zéro', () {
    expect(formatDuration(const Duration(minutes: -3), s), '0 min');
  });
}
