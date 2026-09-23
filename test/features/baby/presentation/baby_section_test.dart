import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/baby_section.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

/// Garde le contrôleur autoDispose en vie comme le fait `SettingsPage`.
class _Host extends ConsumerWidget {
  const _Host(this.profile);

  final BabyProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(babySettingsControllerProvider, (_, _) {});
    return Scaffold(body: BabySection(profile: profile));
  }
}

void main() {
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));
  late MockBabyRepository repo;

  setUpAll(() => registerFallbackValue(profile));

  setUp(() {
    repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
  });

  List<Override> overrides() => [
    clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 21))),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    babyRepositoryProvider.overrideWithValue(repo),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
  ];

  testWidgets('choisir « Fille » enregistre le sexe', (tester) async {
    await pumpApp(tester, _Host(profile), overrides: overrides());
    expect(find.text('Sexe'), findsOneWidget);
    await tester.tap(find.text('Fille'));
    await tester.pumpAndSettle();
    verify(
      () => repo.saveProfile('ABCDEFGH', profile.copyWith(sex: BabySex.female)),
    ).called(1);
  });

  testWidgets('retoucher le sexe choisi l\'efface', (tester) async {
    await pumpApp(
      tester,
      _Host(profile.copyWith(sex: BabySex.male)),
      overrides: overrides(),
    );
    await tester.tap(find.text('Garçon'));
    await tester.pumpAndSettle();
    verify(() => repo.saveProfile('ABCDEFGH', profile)).called(1);
  });
}
