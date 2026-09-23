import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final s = lookupS(const Locale('fr'));

  test('formatSleepDuration', () {
    expect(formatSleepDuration(const Duration(minutes: 42), s), '42 min');
    expect(formatSleepDuration(const Duration(hours: 2), s), '2 h');
    expect(
      formatSleepDuration(const Duration(hours: 1, minutes: 5), s),
      '1 h 05',
    );
    expect(
      formatSleepDuration(const Duration(hours: 13, minutes: 40), s),
      '13 h 40',
    );
    expect(formatSleepDuration(const Duration(seconds: 30), s), '0 min');
    expect(formatSleepDuration(const Duration(minutes: -1), s), '0 min');
  });
}
