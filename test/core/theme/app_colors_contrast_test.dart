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

void main() {
  const minAaContrast = 4.5;

  for (final background in [
    (name: 'primaryContainer', color: AppColors.primaryContainer.light),
    (name: 'surface', color: AppColors.surface.light),
    (name: 'pageBackground', color: AppColors.pageBackground.light),
  ]) {
    test(
      'textSecondary.light sur ${background.name}.light : contraste AA (≥ 4,5)',
      () {
        final ratio = contrastRatio(
          AppColors.textSecondary.light,
          background.color,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(minAaContrast),
          reason:
              'contraste ${ratio.toStringAsFixed(2)} entre textSecondary.light '
              'et ${background.name}.light',
        );
      },
    );
  }
}
