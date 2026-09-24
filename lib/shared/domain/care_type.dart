/// Catégorie d'un soin, pour la couleur et l'icône.
enum CareCategory { feeding, diaper, care, bath }

/// Soins cochables dans un événement.
enum CareType {
  pee(CareCategory.diaper),
  poop(CareCategory.diaper),
  diaperChange(CareCategory.diaper),
  adrigyl(CareCategory.care),
  bath(CareCategory.bath),
  eyeCare(CareCategory.care),
  noseCare(CareCategory.care),
  umbilicalCare(CareCategory.care);

  const CareType(this.category);

  final CareCategory category;

  /// Soins avec une fréquence attendue, dans l'ordre de l'accueil, des réglages et du digest.
  static const List<CareType> scheduled = [
    adrigyl,
    eyeCare,
    noseCare,
    umbilicalCare,
    bath,
  ];

  /// `true` si ce soin a une fréquence attendue.
  bool get isScheduled => scheduled.contains(this);
}
