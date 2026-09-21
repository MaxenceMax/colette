import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/shared/ui/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('affiche le bandeau hors ligne', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: OfflineBanner()),
      overrides: [isOnlineProvider.overrideWith((ref) => Stream.value(false))],
    );
    expect(find.textContaining('Hors ligne'), findsOneWidget);
  });

  testWidgets('reste vide en ligne', (tester) async {
    await pumpApp(tester, const Scaffold(body: OfflineBanner()));
    expect(find.textContaining('Hors ligne'), findsNothing);
  });
}
