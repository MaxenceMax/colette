import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Monte [child] dans une `MaterialApp` fr avec le thème Colette
/// et un `ProviderScope` surchargeable.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  final hasOnlineOverride = overrides.any(
    (override) => override.origin == isOnlineProvider,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (!hasOnlineOverride)
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
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
