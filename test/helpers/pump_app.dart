import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/device/bottle_timer_system.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_session_providers.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fake_bottle_timer_system.dart';
import 'fake_photo_sharing_system.dart';
import 'in_memory_bottle_timer_session_repository.dart';
import 'in_memory_photo_sharing_repository.dart';

/// Monte [child] dans une `MaterialApp` fr avec le thème Colette
/// et un `ProviderScope` surchargeable.
///
/// [viewSize], si renseigné, fixe la taille de la vue de test (utile pour
/// reproduire une largeur d'iPhone précise) et force `devicePixelRatio` à 1
/// (la taille est alors exprimée en points logiques) ; la taille est
/// restaurée après le test.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Size? viewSize,
}) async {
  if (viewSize != null) {
    tester.view.physicalSize = viewSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  bool overridden(Object provider) =>
      overrides.any((override) => override.origin == provider);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (!overridden(isOnlineProvider))
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
        if (!overridden(bottleTimerSystemProvider))
          bottleTimerSystemProvider.overrideWithValue(FakeBottleTimerSystem()),
        if (!overridden(bottleTimerSessionRepositoryProvider))
          bottleTimerSessionRepositoryProvider.overrideWithValue(
            InMemoryBottleTimerSessionRepository(),
          ),
        if (!overridden(photoSharingRepositoryProvider))
          photoSharingRepositoryProvider.overrideWithValue(
            InMemoryPhotoSharingRepository(),
          ),
        if (!overridden(photoSharingSystemProvider))
          photoSharingSystemProvider.overrideWithValue(
            FakePhotoSharingSystem(),
          ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: const ThemeService().light(),
        locale: const Locale('fr'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
