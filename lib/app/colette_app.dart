import 'package:colette/app/notifications_gate.dart';
import 'package:colette/app/router/app_router.dart';
import 'package:colette/app/splash_intro.dart';
import 'package:colette/core/theme/theme_mode_controller.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Racine de l'app : thèmes, locale française, routeur, intro de lancement.
class ColetteApp extends ConsumerWidget {
  const ColetteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const themeService = ThemeService();
    return MaterialApp.router(
      onGenerateTitle: (context) => S.of(context).appTitle,
      theme: themeService.light(),
      darkTheme: themeService.dark(),
      themeMode: ref.watch(themeModeControllerProvider),
      locale: const Locale('fr'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => SplashIntro(
        child: NotificationsGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
