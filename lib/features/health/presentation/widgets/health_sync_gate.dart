import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rafraîchit rappels santé et calendrier au lancement, dès qu'un foyer existe,
/// puis à chaque nouvel état des visites ou des RDV libres (retour du réseau,
/// saisie de l'autre iPhone).
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
    // La sync relit le serveur et ne fait rien hors ligne : la relancer sur
    // chaque émission, cache compris, suffit (les appels sont fusionnés).
    ref.listenManual(medicalVisitsProvider, (_, next) {
      if (next is AsyncData) ref.read(healthSyncProvider).sync();
    });
    ref.listenManual(medicalAppointmentsProvider, (_, next) {
      if (next is AsyncData) ref.read(healthSyncProvider).sync();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
