import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/household/data/prefs_household_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ensureDeviceId crée l\'identifiant une seule fois', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await PrefsHouseholdLocalStore.ensureDeviceId(
      prefs,
      const FixedIdGenerator('dev-1'),
    );
    await PrefsHouseholdLocalStore.ensureDeviceId(
      prefs,
      const FixedIdGenerator('dev-2'),
    );
    expect(PrefsHouseholdLocalStore(prefs).deviceId, 'dev-1');
  });

  test('sauvegarde, lit et efface le code foyer', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PrefsHouseholdLocalStore(prefs);
    expect(store.householdCode, isNull);
    await store.saveHouseholdCode('ABCDEFGH');
    expect(store.householdCode, 'ABCDEFGH');
    await store.clearHouseholdCode();
    expect(store.householdCode, isNull);
  });
}
