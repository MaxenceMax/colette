import 'dart:async';

import 'package:colette/app/router/app_router.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enregistre le push dès qu'un foyer existe et navigue à l'ouverture d'une notification.
class NotificationsGate extends ConsumerStatefulWidget {
  const NotificationsGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationsGate> createState() => _NotificationsGateState();
}

class _NotificationsGateState extends ConsumerState<NotificationsGate> {
  StreamSubscription<Map<String, String>>? _openedSubscription;

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentHouseholdCodeProvider, fireImmediately: true, (
      _,
      code,
    ) {
      if (code != null) ref.read(pushRegistrationProvider.notifier).register();
    });
    final source = ref.read(pushTokenSourceProvider);
    _openedSubscription = source.onMessageOpened.listen(_navigate);
    source.getInitialMessageData().then((data) {
      if (!mounted || data == null) return;
      _navigate(data);
    });
  }

  void _navigate(Map<String, String> data) {
    final route = data['route'];
    if (route == null || !route.startsWith('/')) return;
    ref.read(appRouterProvider).go(route);
  }

  @override
  void dispose() {
    _openedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
