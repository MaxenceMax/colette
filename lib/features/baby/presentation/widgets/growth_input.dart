/// Conversion des saisies de la feuille de mesure en valeurs entières.
abstract final class GrowthInput {
  /// Saisie illisible : hors de toutes les bornes, la validation la refuse
  /// avec la raison du champ concerné.
  static const unreadable = -1;

  static final _spaces = RegExp(r'\s');

  /// Grammes saisis (espaces ignorés) ; `null` si le champ est vide.
  static int? grams(String text) {
    final cleaned = text.replaceAll(_spaces, '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned) ?? unreadable;
  }

  /// Centimètres saisis (virgule ou point) en millimètres ; `null` si vide.
  static int? millimetres(String text) {
    final cleaned = text.replaceAll(_spaces, '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final cm = double.tryParse(cleaned);
    return cm == null ? unreadable : (cm * 10).round();
  }
}
