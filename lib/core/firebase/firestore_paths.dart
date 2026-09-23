/// Noms des collections Firestore.
abstract final class FirestorePaths {
  static const households = 'households';
  static const events = 'events';

  /// Mesures de croissance (poids, taille, périmètre crânien) ; nom historique.
  static const weights = 'weights';
  static const devices = 'devices';
  static const sleeps = 'sleeps';
  static const tastings = 'tastings';
  static const customFoods = 'customFoods';

  /// Visites médicales, une par étape du calendrier (identifiant = `MedicalStageId.name`).
  static const medicalVisits = 'medicalVisits';
}
