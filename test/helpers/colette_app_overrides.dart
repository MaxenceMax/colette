import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/device/bottle_timer_system.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/domain/push_token_source.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_system.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'documents_repository_override.dart';
import 'fake_bottle_timer_system.dart';
import 'fake_photo_sharing_system.dart';
import 'fake_push_token_source.dart';
import 'in_memory_household_local_store.dart';

/// Overrides pour monter l'app entière (`ColetteApp`, routeur réel) en test.
Future<List<Override>> coletteAppOverrides({
  String? householdCode,
  String deviceId = 'device-test',
  Override? documents,
  FakeFirebaseFirestore? firestore,
  PushTokenSource? pushTokenSource,
  BottleTimerSystem? bottleTimerSystem,
  PhotoSharingSystem? photoSharingSystem,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    documents ?? documentsRepositoryOverride(),
    sharedPreferencesProvider.overrideWithValue(prefs),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(
        householdCode: householdCode,
        deviceId: deviceId,
      ),
    ),
    isOnlineProvider.overrideWith((ref) => Stream.value(true)),
    firestoreProvider.overrideWithValue(firestore ?? FakeFirebaseFirestore()),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    pushTokenSourceProvider.overrideWithValue(
      pushTokenSource ?? FakePushTokenSource(),
    ),
    healthSyncProvider.overrideWithValue(const NoopHealthSync()),
    bottleTimerSystemProvider.overrideWithValue(
      bottleTimerSystem ?? FakeBottleTimerSystem(),
    ),
    photoSharingSystemProvider.overrideWithValue(
      photoSharingSystem ?? FakePhotoSharingSystem(),
    ),
  ];
}
