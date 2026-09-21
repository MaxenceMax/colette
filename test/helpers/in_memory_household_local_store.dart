import 'package:colette/features/household/domain/repositories/household_local_store.dart';

/// Stockage local en mémoire pour les tests.
class InMemoryHouseholdLocalStore implements HouseholdLocalStore {
  InMemoryHouseholdLocalStore({
    this.householdCode,
    this.deviceId = 'device-test',
  });

  @override
  String? householdCode;

  @override
  final String deviceId;

  @override
  Future<void> saveHouseholdCode(String code) async => householdCode = code;

  @override
  Future<void> clearHouseholdCode() async => householdCode = null;
}
