import 'dart:async';

import 'package:colette/app/router/app_router.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reprogramme le rappel photo (démarrage, retour au premier plan, prénom
/// chargé ou modifié) et ouvre la page Photos à l'appui sur la notification.
class PhotoReminderGate extends ConsumerStatefulWidget {
  const PhotoReminderGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PhotoReminderGate> createState() => _PhotoReminderGateState();
}

class _PhotoReminderGateState extends ConsumerState<PhotoReminderGate>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _routeSignals;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Resynchronise quand le prénom se charge ou change.
    ref.listenManual(
      babyProfileProvider.select((profile) => profile.value?.name),
      (_, _) => _sync(),
      fireImmediately: true,
    );
    final system = ref.read(photoSharingSystemProvider);
    _routeSignals = system.pendingRouteSignals.listen(
      (_) => unawaited(_openPendingRoute()),
    );
    unawaited(_openPendingRoute());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  void _sync() {
    if (ref.read(currentHouseholdCodeProvider) == null) return;
    unawaited(ref.read(photoReminderSyncProvider).sync());
  }

  Future<void> _openPendingRoute() async {
    final route = await ref.read(photoSharingSystemProvider).takePendingRoute();
    if (!mounted || route != AppRoutes.todayPhotos) return;
    if (ref.read(currentHouseholdCodeProvider) == null) return;
    ref.read(appRouterProvider).go(AppRoutes.todayPhotos);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeSignals?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
