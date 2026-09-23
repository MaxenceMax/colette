import 'package:flutter/material.dart';

/// Palette « Cocon cannelle ». Chaque token porte sa valeur claire et sombre.
enum AppColors {
  // Marque
  /// Cannelle : actions, accents, onglet actif.
  primary(light: Color(0xFFA8573F), dark: Color(0xFFD08A6F)),
  onPrimary(light: Color(0xFFFFFFFF), dark: Color(0xFF1C1514)),

  /// Poudre : lignes de tâches, fonds légers.
  primaryContainer(light: Color(0xFFF3E2DA), dark: Color(0xFF3A2A24)),

  /// Rose poudré : compteurs, badges.
  secondary(light: Color(0xFFE9B9A8), dark: Color(0xFF86584B)),
  onSecondary(light: Color(0xFF5C2A1B), dark: Color(0xFFF7E6E0)),

  /// Miel : fonds et décorations uniquement, jamais en texte (contraste insuffisant en clair).
  accent(light: Color(0xFFD9A441), dark: Color(0xFFE4B85C)),

  // Surfaces
  /// Lin : fond des écrans.
  pageBackground(light: Color(0xFFFBF5EF), dark: Color(0xFF1C1514)),
  surface(light: Color(0xFFFFFFFF), dark: Color(0xFF2B2220)),
  surfaceContainer(light: Color(0xFFF6EBE4), dark: Color(0xFF342925)),

  // Texte
  onSurface(light: Color(0xFF2E2320), dark: Color(0xFFF1E6E0)),

  /// Assombri (0x7B655E → 0x756059) : contraste WCAG sur `primaryContainer.light`
  /// passait de 4,32 (< 4,5) à 4,67.
  textSecondary(light: Color(0xFF756059), dark: Color(0xFFB8A39B)),
  border(light: Color(0xFFEAD9CF), dark: Color(0xFF4A3A34)),

  // Sémantique
  /// Eucalyptus : fait, validé. Valeurs claires assombries pour rester lisibles en texte.
  success(light: Color(0xFF57795D), dark: Color(0xFF9DBBA2)),
  warning(light: Color(0xFF8F6412), dark: Color(0xFFE4B85C)),

  /// Assombri (0xC0563F → 0xB4503B) : contraste WCAG sur `pageBackground.light`
  /// passait de 4,18 (< 4,5) à 4,68.
  error(light: Color(0xFFB4503B), dark: Color(0xFFE27A62)),

  // Catégories de soins
  categoryFeeding(light: Color(0xFFA8573F), dark: Color(0xFFD08A6F)),
  categoryDiaper(light: Color(0xFF8F6412), dark: Color(0xFFE4B85C)),
  categoryCare(light: Color(0xFF57795D), dark: Color(0xFF9DBBA2)),
  categoryBath(light: Color(0xFFA8624F), dark: Color(0xFFC98A79)),

  // Graphiques
  /// Eucalyptus : courbes et zone de référence OMS, distinctes des mesures cannelle.
  growthReference(light: Color(0xFF57795D), dark: Color(0xFF9DBBA2)),

  shadow(light: Color(0xFF000000), dark: Color(0xFFFFFFFF));

  const AppColors({required this.light, required this.dark});

  /// Valeur en thème clair.
  final Color light;

  /// Valeur en thème sombre.
  final Color dark;

  /// Valeur selon [isDark].
  Color resolve({required bool isDark}) => isDark ? dark : light;

  /// Valeur selon le thème du [context].
  Color fromContext(BuildContext context) =>
      resolve(isDark: Theme.of(context).brightness == Brightness.dark);
}

/// Accès aux couleurs depuis un `BuildContext`.
extension BuildContextAppColors on BuildContext {
  /// Couleur du token selon le thème courant.
  Color appColor(AppColors color) => color.fromContext(this);
}
