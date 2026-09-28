import 'dart:async';

import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/device/bottle_timer_system.dart';
import 'package:colette/features/events/domain/use_cases/resumable_bottle_timer_session.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_session_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Au démarrage, rouvre un minuteur de biberon interrompu (app tuée) sur
/// Aujourd'hui, ou ferme une Live Activity orpheline.
class BottleTimerResumeGate extends ConsumerStatefulWidget {
  const BottleTimerResumeGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BottleTimerResumeGate> createState() =>
      _BottleTimerResumeGateState();
}

class _BottleTimerResumeGateState extends ConsumerState<BottleTimerResumeGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentHouseholdCodeProvider, fireImmediately: true, (
      _,
      code,
    ) {
      if (code == null || _checked) return;
      _checked = true;
      unawaited(_resume());
    });
  }

  Future<void> _resume() async {
    final session = await resumableBottleTimerSession(
      repository: ref.read(bottleTimerSessionRepositoryProvider),
      now: ref.read(clockProvider).now(),
    );
    if (!mounted) return;
    if (session == null) {
      await ref.read(bottleTimerSystemProvider).clear();
      return;
    }
    ref.read(bottleTimerResumeProvider.notifier).offer(session);
    ref.read(appRouterProvider).go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
