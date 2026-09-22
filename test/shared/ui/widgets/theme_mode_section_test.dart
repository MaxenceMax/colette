import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/theme/theme_mode_controller.dart';
import 'package:colette/shared/ui/widgets/theme_mode_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('propose Auto, Clair, Sombre et enregistre le choix', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpApp(
      tester,
      const Scaffold(body: ThemeModeSection()),
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Clair'), findsOneWidget);
    expect(find.text('Sombre'), findsOneWidget);

    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();

    expect(prefs.getString(ThemeModeController.prefsKey), 'dark');
    final button = tester.widget<SegmentedButton<ThemeMode>>(
      find.byType(SegmentedButton<ThemeMode>),
    );
    expect(button.selected, {ThemeMode.dark});
  });
}
