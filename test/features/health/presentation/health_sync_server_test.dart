import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockMedicalRepository extends Mock implements MedicalRepository {}

void main() {
  const code = 'ABCDEFGH';
  final now = DateTime(2026, 10, 20, 12);

  setUpAll(() {
    registerFallbackValue(
      MedicalReminderSnapshot(stages: const [], computedAt: now),
    );
  });

  test(
    'serveur injoignable : ni snapshot, ni calendrier (pas de cache)',
    () async {
      SharedPreferences.setMockInitialValues({
        SelectedCalendar.idKey: 'c1',
        SelectedCalendar.titleKey: 'Famille',
      });
      final prefs = await SharedPreferences.getInstance();
      final db = FakeFirebaseFirestore();
      final calendar = MockCalendarRepository();
      final medical = MockMedicalRepository();
      when(() => medical.fetchVisitsFromServer(code))
          .thenAnswer((_) async => left(const NetworkFailure()));
      when(() => medical.fetchAppointmentsFromServer(code))
          .thenAnswer((_) async => right(const []));
      final c = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(FixedClock(now)),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: code),
          ),
          calendarRepositoryProvider.overrideWithValue(calendar),
          medicalRepositoryProvider.overrideWithValue(medical),
        ],
      );
      addTearDown(c.dispose);
      await c
          .read(babyRepositoryProvider)
          .saveProfile(
            code,
            BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
          );

      await c.read(healthSyncProvider).sync();

      verify(() => medical.fetchVisitsFromServer(code)).called(1);
      verifyNever(() => medical.watchVisits(any()));
      verifyNever(() => medical.saveReminderSnapshot(any(), any()));
      verifyZeroInteractions(calendar);
    },
  );
}
