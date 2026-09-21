import 'package:colette/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppSpacing.only et symmetric mettent 0 sur les côtés omis', () {
    expect(
      AppSpacing.only(left: AppSpacing.sm, top: AppSpacing.md),
      const EdgeInsets.only(left: 8, top: 16),
    );
    expect(
      AppSpacing.symmetric(horizontal: AppSpacing.lg),
      const EdgeInsets.symmetric(horizontal: 24),
    );
  });

  test('AppRadius.topOnly n\'arrondit que le haut', () {
    expect(
      AppRadius.lg.topOnly,
      const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
    );
  });

  test('AppElevation.none ne produit aucune ombre', () {
    expect(AppElevation.none.boxShadow(const Color(0xFF000000)), isEmpty);
    expect(AppElevation.low.boxShadow(const Color(0xFF000000)), hasLength(1));
  });

  test('AppOpacity.applyTo conserve la couleur et change l\'alpha', () {
    final color = AppOpacity.medium.applyTo(const Color(0xFF123456));
    expect(color.a, closeTo(0.5, 0.01));
    expect(color.r, closeTo(0x12 / 255, 0.01));
  });
}
