import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_age_band.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  test(
    'sleepSummary et sleepAgeBand combinent flux, horloge et profil',
    () async {
      final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 15));
      final container = ProviderContainer(
        overrides: [
          sleepRepositoryProvider.overrideWithValue(
            FakeSleepRepository([ongoing]),
          ),
          clockProvider.overrideWithValue(FixedClock(now)),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
          ),
          babyProfileProvider.overrideWith(
            (ref) => Stream.value(
              BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(sleepSummaryProvider, (_, _) {});
      container.listen(sleepAgeBandProvider, (_, _) {});
      await container.read(recentSleepsProvider.future);
      await container.read(latestSleepProvider.future);
      await container.read(babyProfileProvider.future);
      final summary = container.read(sleepSummaryProvider)!;
      expect(summary.status, SleepStatus.asleep(ongoing));
      expect(summary.last24h, const Duration(hours: 1));
      expect(container.read(sleepAgeBandProvider), SleepAgeBand.under4Months);
    },
  );
}
