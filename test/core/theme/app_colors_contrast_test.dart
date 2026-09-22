import 'dart:math';

import 'package:colette/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Luminance relative WCAG d'une composante sRGB (0.0-1.0).
double _linearChannel(double c) =>
    c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();

/// Luminance relative WCAG d'une [Color] (0 = noir, 1 = blanc).
double _relativeLuminance(Color color) {
  final r = _linearChannel(color.r);
  final g = _linearChannel(color.g);
  final b = _linearChannel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Ratio de contraste WCAG entre deux couleurs (1 à 21 ; ≥ 4,5 pour du texte
/// normal selon le niveau AA).
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = max(la, lb);
  final darker = min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Paires (premier plan, fond) réellement utilisées par les widgets.
const _pairs = [
  (AppColors.onSurface, AppColors.surface),
  (AppColors.onSurface, AppColors.pageBackground),
  (AppColors.onSurface, AppColors.surfaceContainer),
  (AppColors.onSurface, AppColors.primaryContainer),
  (AppColors.textSecondary, AppColors.surface),
  (AppColors.textSecondary, AppColors.pageBackground),
  (AppColors.textSecondary, AppColors.surfaceContainer),
  (AppColors.textSecondary, AppColors.primaryContainer),
  (AppColors.primary, AppColors.surface),
  (AppColors.primary, AppColors.pageBackground),
  (AppColors.onPrimary, AppColors.primary),
  (AppColors.onSecondary, AppColors.secondary),
  (AppColors.error, AppColors.surface),
  (AppColors.error, AppColors.pageBackground),
  (AppColors.success, AppColors.surface),
  (AppColors.success, AppColors.pageBackground),
  (AppColors.warning, AppColors.surface),
  (AppColors.onPrimary, AppColors.warning),
  (AppColors.onPrimary, AppColors.categoryFeeding),
  (AppColors.onPrimary, AppColors.categoryDiaper),
  (AppColors.onPrimary, AppColors.categoryCare),
  (AppColors.onPrimary, AppColors.categoryBath),
];

void main() {
  const minAaContrast = 4.5;

  for (final (foreground, background) in _pairs) {
    for (final (theme, pick) in [
      ('clair', (AppColors c) => c.light),
      ('sombre', (AppColors c) => c.dark),
    ]) {
      test(
        '${foreground.name} sur ${background.name} en thème $theme : AA (≥ 4,5)',
        () {
          final ratio = contrastRatio(pick(foreground), pick(background));
          expect(
            ratio,
            greaterThanOrEqualTo(minAaContrast),
            reason:
                'contraste ${ratio.toStringAsFixed(2)} entre ${foreground.name} '
                'et ${background.name} ($theme)',
          );
        },
      );
    }
  }
}
