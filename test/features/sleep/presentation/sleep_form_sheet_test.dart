import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_form_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  List<Override> overrides(FakeSleepRepository repo, {BabyProfile? profile}) =>
      [
        sleepRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(
            profile ?? BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)),
          ),
        ),
      ];

  Future<void> open(
    WidgetTester tester,
    FakeSleepRepository repo, {
    SleepSession? initial,
    BabyProfile? profile,
    bool pickEndOnOpen = false,
  }) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showSleepFormSheet(
            context,
            initial: initial,
            pickEndOnOpen: pickEndOnOpen,
          ),
          child: const Text('ouvrir'),
        ),
      ),
      overrides: overrides(repo, profile: profile),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  SegmentedButton<SleepKind> kindButton(WidgetTester tester) =>
      tester.widget<SegmentedButton<SleepKind>>(
        find.byType(SegmentedButton<SleepKind>),
      );

  testWidgets('nouveau sommeil : 15h00 → 16h00, sieste, enregistré', (
    tester,
  ) async {
    final repo = FakeSleepRepository();
    await open(tester, repo);
    expect(find.text('Nouveau sommeil'), findsOneWidget);
    expect(find.text('15h00'), findsOneWidget);
    expect(find.text('16h00'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved = repo.saved.single;
    expect(saved.id, 'new');
    expect(saved.startAt, DateTime(2026, 9, 23, 15));
    expect(saved.endAt, DateTime(2026, 9, 23, 16));
    expect(saved.kind, SleepKind.nap);
    expect(find.text('Nouveau sommeil'), findsNothing);
  });

  testWidgets(
    'les heures de nuit du profil pré-remplissent Nuit sur un nouveau sommeil',
    (tester) async {
      final repo = FakeSleepRepository();
      await open(
        tester,
        repo,
        profile: BabyProfile(
          name: 'C',
          birthDate: DateTime(2026, 9, 1),
          careSettings: const CareSettings(
            nightStartHour: 14,
            nightEndHour: 18,
          ),
        ),
      );
      expect(kindButton(tester).selected, {SleepKind.night});
    },
  );

  testWidgets('chevauchement : message dans le formulaire, rien d\'écrit', (
    tester,
  ) async {
    final repo = FakeSleepRepository([
      makeSleep(
        id: 'o',
        startAt: DateTime(2026, 9, 23, 14, 10),
        endAt: DateTime(2026, 9, 23, 15, 30),
      ),
    ]);
    await open(tester, repo);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Chevauche le sommeil de 14h10 à 15h30.'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });

  testWidgets('l\'erreur disparaît après une modification de champ', (
    tester,
  ) async {
    final repo = FakeSleepRepository([
      makeSleep(
        id: 'o',
        startAt: DateTime(2026, 9, 23, 14, 10),
        endAt: DateTime(2026, 9, 23, 15, 30),
      ),
    ]);
    await open(tester, repo);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Chevauche le sommeil de 14h10 à 15h30.'), findsOneWidget);
    await tester.tap(find.text('Nuit'));
    await tester.pump();
    expect(find.text('Chevauche le sommeil de 14h10 à 15h30.'), findsNothing);
  });

  testWidgets('édition : Nuit sélectionnée et suppression confirmée', (
    tester,
  ) async {
    final existing = makeSleep(
      id: 'x',
      kind: SleepKind.night,
      startAt: DateTime(2026, 9, 23, 2),
      endAt: DateTime(2026, 9, 23, 5),
    );
    final repo = FakeSleepRepository([existing]);
    await open(tester, repo, initial: existing);
    expect(find.text('Modifier le sommeil'), findsOneWidget);
    expect(kindButton(tester).selected, {SleepKind.night});
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(repo.deleted, ['x']);
  });

  testWidgets('sommeil en cours : fin affichée « En cours »', (tester) async {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 15));
    await open(tester, FakeSleepRepository([ongoing]), initial: ongoing);
    expect(find.text('En cours'), findsOneWidget);
  });

  testWidgets('en cours : Enregistrer garde endAt à null', (tester) async {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 15));
    final repo = FakeSleepRepository([ongoing]);
    await open(tester, repo, initial: ongoing);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(repo.saved.single.endAt, isNull);
  });

  testWidgets('pickEndOnOpen ouvre le sélecteur de fin', (tester) async {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 15));
    await open(
      tester,
      FakeSleepRepository([ongoing]),
      initial: ongoing,
      pickEndOnOpen: true,
    );
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
  });

  testWidgets('« Toujours en cours » remet la fin à vide', (tester) async {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 15));
    await open(
      tester,
      FakeSleepRepository([ongoing]),
      initial: ongoing,
      pickEndOnOpen: true,
    );
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    picker.onDateTimeChanged(DateTime(2026, 9, 23, 15, 30));
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();
    expect(find.text('15h30'), findsOneWidget);
    expect(find.text('Toujours en cours'), findsOneWidget);
    await tester.tap(find.text('Toujours en cours'));
    await tester.pumpAndSettle();
    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Toujours en cours'), findsNothing);
  });
}
