/// Vaccins du calendrier ; `name` sert de clé Firestore.
enum VaccineCode {
  /// DTCaP-Hib-HépB (diphtérie, tétanos, coqueluche, polio, Haemophilus, hépatite B).
  hexavalent,
  pneumococcal,
  menB,
  menACWY,

  /// ROR (rougeole, oreillons, rubéole).
  mmr,
  rotavirus,
}
