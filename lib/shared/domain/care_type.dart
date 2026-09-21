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
}
