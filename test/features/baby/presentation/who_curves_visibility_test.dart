import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/presentation/providers/who_curves_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, SharedPreferences)> makeContainer(
    Map<String, Object> initial,
  ) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return (container, prefs);
  }

  test('cachées par défaut', () async {
    final (container, _) = await makeContainer({});
    expect(container.read(whoCurvesVisibilityProvider), isFalse);
  });

  test('relit le choix enregistré sur l\'appareil', () async {
    final (container, _) = await makeContainer({
      WhoCurvesVisibility.prefsKey: true,
    });
    expect(container.read(whoCurvesVisibilityProvider), isTrue);
  });

  test('set met à jour l\'état et le stockage', () async {
    final (container, prefs) = await makeContainer({});
    await container.read(whoCurvesVisibilityProvider.notifier).set(true);
    expect(container.read(whoCurvesVisibilityProvider), isTrue);
    expect(prefs.getBool(WhoCurvesVisibility.prefsKey), isTrue);
  });
}
