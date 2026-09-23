/// Groupes alimentaires OMS/UNICEF de la diversité alimentaire minimale, sans le
/// lait maternel, plus [outsideGroups] pour ce qui ne compte pas (graisses, sucre…).
enum FoodGroup {
  grainsRootsTubers,
  legumesNutsSeeds,
  dairy,
  fleshFoods,
  eggs,
  vitaminAFruitsVeg,
  otherFruitsVeg,
  outsideGroups;

  /// `true` si le groupe compte dans la diversité alimentaire du jour.
  bool get countsForDiversity => this != outsideGroups;

  /// Les 7 groupes comptés, dans l'ordre OMS.
  static List<FoodGroup> get diversityGroups =>
      values.where((group) => group.countsForDiversity).toList();
}
