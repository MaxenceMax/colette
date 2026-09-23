/// Âges de référence de la diversification.
abstract final class DiversificationAges {
  /// Début recommandé par l'OMS.
  static const whoStartMonths = 6;

  /// Âge minimal selon les recommandations françaises (Anses, SPF).
  static const franceMinMonths = 4;
}

/// Phase OMS de l'alimentation complémentaire.
enum DiversificationPhase {
  preparation,
  months6To8,
  months9To11,
  months12To23;

  /// Phase à [ageMonths] mois révolus ; au-delà de 23 mois, reste en 12–23.
  static DiversificationPhase forAgeMonths(int ageMonths) =>
      switch (ageMonths) {
        < DiversificationAges.whoStartMonths => preparation,
        < 9 => months6To8,
        < 12 => months9To11,
        _ => months12To23,
      };
}
