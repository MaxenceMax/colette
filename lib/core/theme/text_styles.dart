import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Styles de texte Colette : titres et nombres en Fraunces, corps en DM Sans.
enum ColetteTextStyle {
  displayTitle,
  heading1,
  heading2,
  heading3,
  numberLarge,
  numberMedium,
  bodyLarge,
  body,
  bodyMedium,
  label,
  small,
  overline;

  TextStyle get textStyle => switch (this) {
    ColetteTextStyle.displayTitle => GoogleFonts.fraunces(
      fontSize: 32,
      fontWeight: .w600,
      height: 1.15,
    ),
    ColetteTextStyle.heading1 => GoogleFonts.fraunces(
      fontSize: 26,
      fontWeight: .w600,
      height: 1.2,
    ),
    ColetteTextStyle.heading2 => GoogleFonts.fraunces(
      fontSize: 20,
      fontWeight: .w600,
      height: 1.2,
    ),
    ColetteTextStyle.heading3 => GoogleFonts.fraunces(
      fontSize: 17,
      fontWeight: .w600,
      height: 1.2,
    ),
    ColetteTextStyle.numberLarge => GoogleFonts.fraunces(
      fontSize: 40,
      fontWeight: .w600,
      height: 1.0,
    ),
    ColetteTextStyle.numberMedium => GoogleFonts.fraunces(
      fontSize: 24,
      fontWeight: .w600,
      height: 1.0,
    ),
    ColetteTextStyle.bodyLarge => GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: .w400,
      height: 1.4,
    ),
    ColetteTextStyle.body => GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: .w400,
      height: 1.4,
    ),
    ColetteTextStyle.bodyMedium => GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: .w500,
      height: 1.4,
    ),
    ColetteTextStyle.label => GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: .w500,
      height: 1.3,
    ),
    ColetteTextStyle.small => GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: .w400,
      height: 1.3,
    ),
    ColetteTextStyle.overline => GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: .w500,
      height: 1.3,
      letterSpacing: 0.66,
    ),
  };
}

/// Accès nommé aux styles : `Theme.of(context).coletteTextStyles.heading1`.
class ColetteTextStyles {
  const ColetteTextStyles();

  TextStyle get displayTitle => ColetteTextStyle.displayTitle.textStyle;
  TextStyle get heading1 => ColetteTextStyle.heading1.textStyle;
  TextStyle get heading2 => ColetteTextStyle.heading2.textStyle;
  TextStyle get heading3 => ColetteTextStyle.heading3.textStyle;
  TextStyle get numberLarge => ColetteTextStyle.numberLarge.textStyle;
  TextStyle get numberMedium => ColetteTextStyle.numberMedium.textStyle;
  TextStyle get bodyLarge => ColetteTextStyle.bodyLarge.textStyle;
  TextStyle get body => ColetteTextStyle.body.textStyle;
  TextStyle get bodyMedium => ColetteTextStyle.bodyMedium.textStyle;
  TextStyle get label => ColetteTextStyle.label.textStyle;
  TextStyle get small => ColetteTextStyle.small.textStyle;
  TextStyle get overline => ColetteTextStyle.overline.textStyle;
}

/// Expose [ColetteTextStyles] sur `ThemeData`.
extension ColetteTextStylesX on ThemeData {
  ColetteTextStyles get coletteTextStyles => const ColetteTextStyles();
}
