import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rafraîchit rappels santé et calendrier au lancement, dès qu'un foyer existe.
class HealthSyncGate extends ConsumerStatefulWidget {
  const HealthSyncGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HealthSyncGate> createState() => _HealthSyncGateState();
}

class _HealthSyncGateState extends ConsumerState<HealthSyncGate> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(currentHouseholdCodeProvider, fireImmediately: true, (
      _,
      code,
    ) {
      if (code == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(healthSyncProvider).sync();
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
