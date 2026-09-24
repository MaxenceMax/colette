import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'scheduled liste les cinq soins programmés dans l\'ordre de l\'accueil',
    () {
      expect(CareType.scheduled, [
        CareType.adrigyl,
        CareType.eyeCare,
        CareType.noseCare,
        CareType.umbilicalCare,
        CareType.bath,
      ]);
    },
  );

  test('isScheduled est faux pour pipi, caca et change', () {
    expect(CareType.pee.isScheduled, isFalse);
    expect(CareType.poop.isScheduled, isFalse);
    expect(CareType.diaperChange.isScheduled, isFalse);
    expect(CareType.bath.isScheduled, isTrue);
  });
}
