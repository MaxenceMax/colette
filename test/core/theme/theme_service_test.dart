import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ThemeService();

  test('le thème clair utilise les tokens light', () {
    final theme = service.light();
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppColors.pageBackground.light);
    expect(theme.colorScheme.primary, AppColors.primary.light);
  });

  test('le thème sombre utilise les tokens dark', () {
    final theme = service.dark();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.pageBackground.dark);
    expect(theme.colorScheme.primary, AppColors.primary.dark);
  });

  test('les styles Colette sont accessibles depuis ThemeData', () {
    final theme = service.light();
    expect(theme.coletteTextStyles.heading1.fontSize, 26);
    expect(theme.coletteTextStyles.body.fontSize, 14);
  });
}
