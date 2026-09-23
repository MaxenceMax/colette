import 'package:flutter/material.dart';

/// Espacements.
enum AppSpacing {
  none(0),
  xxs(2),
  xs(4),
  sm(8),
  md(16),
  lg(24),
  xl(32),
  xxl(48),
  xxxl(64);

  const AppSpacing(this.value);

  final double value;

  EdgeInsets get all => EdgeInsets.all(value);
  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: value);
  EdgeInsets get vertical => EdgeInsets.symmetric(vertical: value);
  EdgeInsets get top => EdgeInsets.only(top: value);
  EdgeInsets get bottom => EdgeInsets.only(bottom: value);
  EdgeInsets get left => EdgeInsets.only(left: value);
  EdgeInsets get right => EdgeInsets.only(right: value);
  Widget get verticalSpace => SizedBox(height: value);
  Widget get horizontalSpace => SizedBox(width: value);

  /// Padding avec des valeurs différentes par côté (côtés omis = 0).
  static EdgeInsets only({
    AppSpacing? left,
    AppSpacing? right,
    AppSpacing? top,
    AppSpacing? bottom,
  }) => EdgeInsets.only(
    left: left?.value ?? 0,
    right: right?.value ?? 0,
    top: top?.value ?? 0,
    bottom: bottom?.value ?? 0,
  );

  /// Padding symétrique.
  static EdgeInsets symmetric({AppSpacing? horizontal, AppSpacing? vertical}) =>
      EdgeInsets.symmetric(
        horizontal: horizontal?.value ?? 0,
        vertical: vertical?.value ?? 0,
      );
}

/// Tailles de composants (icônes, boutons, avatars).
enum AppSize {
  nano(8),
  xxs(12),
  xs(16),
  sm(24),
  md(32),
  lg(40),
  xl(48),
  xxl(56),
  xxxl(64),
  huge(80),
  massive(96);

  const AppSize(this.value);

  final double value;

  Widget get square => SizedBox(width: value, height: value);
  Size get size => Size(value, value);
}

/// Rayons de bordure.
enum AppRadius {
  none(0),
  xs(4),
  sm(8),
  md(12),
  lg(16),
  xl(20),
  xxl(24),
  round(999);

  const AppRadius(this.value);

  final double value;

  BorderRadius get circular => BorderRadius.circular(value);
  Radius get radius => Radius.circular(value);
  BorderRadius get topOnly =>
      BorderRadius.only(topLeft: radius, topRight: radius);
  BorderRadius get bottomOnly =>
      BorderRadius.only(bottomLeft: radius, bottomRight: radius);
}

/// Élévations, traduites en ombres.
enum AppElevation {
  none(0),
  low(2),
  medium(4),
  high(8);

  const AppElevation(this.value);

  final double value;

  /// Ombres correspondantes ; [shadowColor] vient de `AppColors.shadow`.
  List<BoxShadow> boxShadow(Color shadowColor) {
    if (value == 0) return const [];
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.08),
        blurRadius: value * 2,
        offset: Offset(0, value / 2),
      ),
    ];
  }
}

/// Tailles de police brutes, pour les rares cas hors `ColetteTextStyle`.
enum AppFontSize {
  xs(10),
  sm(12),
  md(14),
  lg(16),
  xl(18),
  xxl(20),
  xxxl(24),
  display(32),
  hero(40);

  const AppFontSize(this.value);

  final double value;
}

/// Durées d'animation.
enum AppDuration {
  fast(Duration(milliseconds: 150)),
  normal(Duration(milliseconds: 250)),
  slow(Duration(milliseconds: 350)),

  /// Intro du démarrage à froid (respiration, glissement, fondu).
  splash(Duration(milliseconds: 1100));

  const AppDuration(this.value);

  final Duration value;
}

/// Opacités courantes.
enum AppOpacity {
  veryLight(0.1),
  light(0.25),
  medium(0.5),
  strong(0.75);

  const AppOpacity(this.value);

  final double value;

  /// Applique cette opacité à [color].
  Color applyTo(Color color) => color.withValues(alpha: value);
}

/// Épaisseurs de trait (courbes, grilles de graphiques).
enum AppStroke {
  hairline(1),
  regular(2),
  thick(3);

  const AppStroke(this.value);

  final double value;
}
