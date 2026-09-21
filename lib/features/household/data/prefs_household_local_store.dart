import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/household/domain/repositories/household_local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage local via `shared_preferences`.
class PrefsHouseholdLocalStore implements HouseholdLocalStore {
  PrefsHouseholdLocalStore(this._prefs);

  static const householdCodeKey = 'household_code';
  static const deviceIdKey = 'device_id';

  final SharedPreferences _prefs;

  /// À appeler au démarrage : crée l'identifiant d'appareil s'il manque.
  static Future<void> ensureDeviceId(
    SharedPreferences prefs,
    IdGenerator ids,
  ) async {
    if (!prefs.containsKey(deviceIdKey)) {
      await prefs.setString(deviceIdKey, ids.newId());
    }
  }

  @override
  String? get householdCode => _prefs.getString(householdCodeKey);

  @override
  Future<void> saveHouseholdCode(String code) =>
      _prefs.setString(householdCodeKey, code);

  @override
  Future<void> clearHouseholdCode() => _prefs.remove(householdCodeKey);

  @override
  String get deviceId =>
      _prefs.getString(deviceIdKey) ??
      (throw StateError(
        'PrefsHouseholdLocalStore.ensureDeviceId doit être appelé au démarrage',
      ));
}
