import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'now_providers.g.dart';

/// Émet chaque minute ; surchargé par `Stream.empty()` dans les tests.
@riverpod
Stream<DateTime> minuteTicker(Ref ref) {
  final clock = ref.watch(clockProvider);
  return Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => clock.now(),
  );
}

/// Heure courante, rafraîchie chaque minute.
@riverpod
DateTime currentMinute(Ref ref) {
  ref.watch(minuteTickerProvider);
  return ref.watch(clockProvider).now();
}

/// Jour civil courant ; ne notifie ses dépendants qu'au changement de jour.
@riverpod
DateTime today(Ref ref) => ref.watch(currentMinuteProvider).dateOnly;
