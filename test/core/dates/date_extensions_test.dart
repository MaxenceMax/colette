import 'package:colette/core/dates/date_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dateOnly supprime l\'heure', () {
    expect(DateTime(2026, 9, 21, 14, 30).dateOnly, DateTime(2026, 9, 21));
  });

  test('isSameDay compare le jour civil', () {
    expect(
      DateTime(2026, 9, 21, 1).isSameDay(DateTime(2026, 9, 21, 23)),
      isTrue,
    );
    expect(
      DateTime(2026, 9, 21, 23).isSameDay(DateTime(2026, 9, 22, 0)),
      isFalse,
    );
  });

  test('startOfNextDay renvoie minuit du lendemain', () {
    expect(DateTime(2026, 9, 21, 14).startOfNextDay, DateTime(2026, 9, 22));
  });
}
