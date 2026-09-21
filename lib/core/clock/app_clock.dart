import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_clock.g.dart';

/// Horloge injectable pour rendre les calculs de dates testables.
abstract interface class AppClock {
  DateTime now();
}

/// Horloge système.
final class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Horloge figée, pour les tests.
final class FixedClock implements AppClock {
  const FixedClock(this.fixed);

  final DateTime fixed;

  @override
  DateTime now() => fixed;
}

/// Horloge de l'app ; surchargée par une [FixedClock] dans les tests.
@riverpod
AppClock clock(Ref ref) => const SystemClock();
