import 'package:colette/features/diversification/domain/entities/pediatrician_advice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const step3 = AdviceStep(fromMonths: 3, items: [AdviceItem(text: 'Yaourts')]);
  const step4 = AdviceStep(fromMonths: 4, items: [AdviceItem(text: 'Purées')]);
  const step6 = AdviceStep(
    fromMonths: 6,
    items: [AdviceItem(text: 'Fruits crus')],
  );
  const advice = PediatricianAdvice(
    title: 'Diversification',
    author: 'Dr',
    scope: 'Sauf HPLV',
    steps: [step3, step4, step6],
    avoid: 'Pas de farine',
  );

  test('currentStep : dernière étape atteinte, aucune avant la première', () {
    expect(advice.currentStep(2), isNull);
    expect(advice.currentStep(3), step3);
    expect(advice.currentStep(5), step4);
    expect(advice.currentStep(14), step6);
  });

  test('AdviceItem : sans détail par défaut', () {
    expect(const AdviceItem(text: 'Yaourts').details, isEmpty);
  });
}
