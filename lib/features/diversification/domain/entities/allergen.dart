/// Les 14 allergènes réglementaires de l'UE (règlement 1169/2011, annexe II).
enum Allergen {
  milk,
  eggs,
  gluten,
  peanut,
  treeNuts,
  fish,
  crustaceans,
  sesame,
  soy,
  celery,
  mustard,
  sulphites,
  lupin,
  molluscs;

  /// Les 9 allergènes suivis par la carte Allergènes, dans l'ordre d'affichage.
  static const tracked = <Allergen>[
    Allergen.milk,
    Allergen.eggs,
    Allergen.gluten,
    Allergen.peanut,
    Allergen.treeNuts,
    Allergen.fish,
    Allergen.crustaceans,
    Allergen.sesame,
    Allergen.soy,
  ];
}
