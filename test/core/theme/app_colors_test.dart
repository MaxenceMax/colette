import 'package:colette/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Color> readPrimary(WidgetTester tester, Brightness brightness) async {
    late Color color;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(
          builder: (context) {
            color = context.appColor(AppColors.primary);
            return const SizedBox();
          },
        ),
      ),
    );
    return color;
  }

  testWidgets('appColor renvoie la valeur light en thème clair', (
    tester,
  ) async {
    expect(
      await readPrimary(tester, Brightness.light),
      AppColors.primary.light,
    );
  });

  testWidgets('appColor renvoie la valeur dark en thème sombre', (
    tester,
  ) async {
    expect(await readPrimary(tester, Brightness.dark), AppColors.primary.dark);
  });
}
