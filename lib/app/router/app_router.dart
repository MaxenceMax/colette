import 'package:colette/app/main_shell.dart';
import 'package:colette/features/baby/presentation/pages/settings_page.dart';
import 'package:colette/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/household/presentation/pages/create_household_page.dart';
import 'package:colette/features/household/presentation/pages/join_household_page.dart';
import 'package:colette/features/household/presentation/pages/onboarding_page.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Chemins des routes.
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const onboardingCreate = '/onboarding/create';
  static const onboardingJoin = '/onboarding/join';
  static const today = '/today';
  static const journal = '/journal';
  static const settings = '/settings';

  /// Paramètre de requête qui ouvre le formulaire biberon à l'arrivée sur Aujourd'hui.
  static const openBottleParam = 'bottle';
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
