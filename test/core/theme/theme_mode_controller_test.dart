import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('suit le système par défaut', () async {
    final container = await makeContainer({});
    expect(container.read(themeModeControllerProvider), ThemeMode.system);
  });

  test('relit le mode enregistré', () async {
    final container = await makeContainer({
      ThemeModeController.prefsKey: 'dark',
    });
    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
  });

  test('ignore une valeur inconnue', () async {
    final container = await makeContainer({
      ThemeModeController.prefsKey: 'sepia',
    });
    expect(container.read(themeModeControllerProvider), ThemeMode.system);
  });

  test('set met à jour l\'état et le stockage', () async {
    final container = await makeContainer({});
    await container
        .read(themeModeControllerProvider.notifier)
        .set(ThemeMode.light);
    expect(container.read(themeModeControllerProvider), ThemeMode.light);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString(ThemeModeController.prefsKey), 'light');
  });
}
