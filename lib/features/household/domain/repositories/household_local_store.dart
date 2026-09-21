/// Ce que l'appareil retient localement : code foyer et identifiant d'appareil.
abstract interface class HouseholdLocalStore {
  String? get householdCode;

  Future<void> saveHouseholdCode(String code);

  Future<void> clearHouseholdCode();

  String get deviceId;
}
