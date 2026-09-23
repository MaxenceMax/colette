import 'package:colette/features/baby/presentation/widgets/growth_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grammes : vide → null, espaces ignorés, illisible → -1', () {
    expect(GrowthInput.grams(''), isNull);
    expect(GrowthInput.grams('  '), isNull);
    expect(GrowthInput.grams('3650'), 3650);
    expect(GrowthInput.grams('3 650'), 3650);
    expect(GrowthInput.grams('3,6'), GrowthInput.unreadable);
  });

  test('centimètres en millimètres : virgule ou point', () {
    expect(GrowthInput.millimetres(''), isNull);
    expect(GrowthInput.millimetres('54,5'), 545);
    expect(GrowthInput.millimetres('54.5'), 545);
    expect(GrowthInput.millimetres('37'), 370);
    expect(GrowthInput.millimetres('5a'), GrowthInput.unreadable);
  });
}
