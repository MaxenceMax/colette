import 'package:colette/app/colette_app.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_push_token_source.dart';
import '../helpers/in_memory_household_local_store.dart';

void main() {
  Future<void> pumpColetteApp(
    WidgetTester tester, {
    required FakePushTokenSource pushSource,
    FakeFirebaseFirestore? firestore,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(
              householdCode: 'ABCDEFGH',
              deviceId: 'dev-1',
            ),
          ),
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          firestoreProvider.overrideWithValue(
            firestore ?? FakeFirebaseFirestore(),
          ),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          pushTokenSourceProvider.overrideWithValue(pushSource),
        ],
        child: const ColetteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('au démarrage avec un foyer, le token est écrit dans Firestore', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    await pumpColetteApp(
      tester,
      pushSource: FakePushTokenSource(granted: true, token: 'tok'),
      firestore: firestore,
    );
    final doc = await firestore
        .collection(FirestorePaths.households)
        .doc('ABCDEFGH')
        .collection(FirestorePaths.devices)
        .doc('dev-1')
        .get();
    expect(doc.data()?['fcmToken'], 'tok');
  });

  testWidgets('ouvrir une notification navigue vers sa route', (tester) async {
    final source = FakePushTokenSource(granted: true, token: 'tok');
    await pumpColetteApp(tester, pushSource: source);
    source.emitOpened({'route': '/journal'});
    await tester.pumpAndSettle();
    expect(find.byType(TimelinePage), findsOneWidget);
  });

  testWidgets(
    'ouvrir la notification biberon depuis Aujourd\'hui ouvre le formulaire',
    (tester) async {
      final source = FakePushTokenSource(granted: true, token: 'tok');
      await pumpColetteApp(tester, pushSource: source);
      source.emitOpened({'route': '/today?bottle=1'});
      await tester.pumpAndSettle();
      expect(find.byType(EventFormSheet), findsOneWidget);
    },
  );

  testWidgets('ouvrir la notification biberon depuis le Journal revient sur '
      'Aujourd\'hui et ouvre le formulaire', (tester) async {
    final source = FakePushTokenSource(granted: true, token: 'tok');
    await pumpColetteApp(tester, pushSource: source);
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    expect(find.byType(TimelinePage), findsOneWidget);
    source.emitOpened({'route': '/today?bottle=1'});
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsOneWidget);
    expect(find.byType(TimelinePage), findsNothing);
  });

  testWidgets('une route invalide est ignorée', (tester) async {
    final source = FakePushTokenSource(granted: true, token: 'tok');
    await pumpColetteApp(tester, pushSource: source);
    source.emitOpened({'route': 'javascript:evil'});
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsNothing);
    expect(find.text('Aujourd\'hui'), findsWidgets);
    source.emitOpened({'route': '/nope'});
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsNothing);
    expect(find.text('Aujourd\'hui'), findsWidgets);
  });

  testWidgets('le message initial est traité au démarrage (route biberon)', (
    tester,
  ) async {
    await pumpColetteApp(
      tester,
      pushSource: FakePushTokenSource(
        granted: true,
        token: 'tok',
        initialMessageData: {'route': '/today?bottle=1'},
      ),
    );
    expect(find.byType(EventFormSheet), findsOneWidget);
  });

  testWidgets(
    'le message initial est traité au démarrage (changement de branche)',
    (tester) async {
      await pumpColetteApp(
        tester,
        pushSource: FakePushTokenSource(
          granted: true,
          token: 'tok',
          initialMessageData: {'route': '/journal'},
        ),
      );
      expect(find.byType(TimelinePage), findsOneWidget);
    },
  );
}
