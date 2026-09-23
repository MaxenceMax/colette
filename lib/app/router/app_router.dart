import 'package:colette/app/main_shell.dart';
import 'package:colette/features/baby/presentation/pages/settings_page.dart';
import 'package:colette/features/baby/presentation/pages/weight_curve_page.dart';
import 'package:colette/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:colette/features/documents/presentation/pages/documents_page.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/household/presentation/pages/create_household_page.dart';
import 'package:colette/features/household/presentation/pages/join_household_page.dart';
import 'package:colette/features/household/presentation/pages/onboarding_page.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/presentation/pages/sleep_page.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Chemins des routes.
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const onboardingCreate = '/onboarding/create';
  static const onboardingJoin = '/onboarding/join';
  static const today = '/today';

  /// Courbe de poids, imbriquée sous Aujourd'hui pour garder la barre d'onglets.
  static const weights = '/today/weights';

  /// Page Sommeil, imbriquée sous Aujourd'hui pour garder la barre d'onglets.
  static const sleep = '/today/sleep';
  static const journal = '/journal';
  static const settings = '/settings';

  /// Paramètre de requête qui ouvre le formulaire biberon à l'arrivée sur Aujourd'hui.
  static const openBottleParam = 'bottle';

  /// Page Documents, imbriquée sous Aujourd'hui pour garder la barre d'onglets.
  static const todayDocuments = '/today/documents';

  /// Paramètre de requête : chemin relatif du dossier affiché.
  static const documentsPathParam = 'path';

  /// Emplacement de la page Documents pour un dossier ([path] vide = racine).
  static String documentsLocation(String path) => path.isEmpty
      ? todayDocuments
      : Uri(
          path: todayDocuments,
          queryParameters: {documentsPathParam: path},
        ).toString();
}

/// Routeur : onboarding tant qu'aucun foyer, sinon shell à trois onglets.
@riverpod
GoRouter appRouter(Ref ref) {
  final hasHousehold = ref.watch(currentHouseholdCodeProvider) != null;
  final router = GoRouter(
    initialLocation: hasHousehold ? AppRoutes.today : AppRoutes.onboarding,
    redirect: (context, state) {
      final onOnboarding = state.matchedLocation.startsWith(
        AppRoutes.onboarding,
      );
      if (!hasHousehold && !onOnboarding) return AppRoutes.onboarding;
      if (hasHousehold && onOnboarding) return AppRoutes.today;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, _) => const CreateHouseholdPage(),
          ),
          GoRoute(path: 'join', builder: (_, _) => const JoinHouseholdPage()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                builder: (_, _) => const DashboardPage(),
                routes: [
                  GoRoute(
                    path: 'weights',
                    builder: (_, _) => const WeightCurvePage(),
                  ),
                  GoRoute(path: 'sleep', builder: (_, _) => const SleepPage()),
                  GoRoute(
                    path: 'documents',
                    builder: (_, state) => DocumentsPage(
                      path:
                          state.uri.queryParameters[AppRoutes
                              .documentsPathParam] ??
                          '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.journal,
                builder: (_, _) => const TimelinePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
