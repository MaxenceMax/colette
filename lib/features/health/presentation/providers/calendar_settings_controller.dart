import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_settings_controller.g.dart';

/// Accès au Calendrier et choix du calendrier des RDV santé sur cet iPhone.
@riverpod
class CalendarSettingsController extends _$CalendarSettingsController {
  @override
  FutureOr<void> build() {}

  /// Demande l'accès puis liste les calendriers modifiables ; `null` en cas d'échec.
  Future<List<DeviceCalendar>?> loadCalendars() async {
    final repo = ref.read(calendarRepositoryProvider);
    state = const AsyncLoading();
    final access = await repo.requestAccess();
    final result = await access
        .fold<Future<Either<Failure, List<DeviceCalendar>>>>(
          (failure) async => left(failure),
          (granted) async => granted
              ? repo.listCalendars()
              : left(const CalendarFailure(CalendarReason.accessDenied)),
        );
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    return result.getRight().toNullable();
  }

  /// Retient [calendar] pour cet iPhone puis synchronise les RDV.
  Future<void> choose(DeviceCalendar calendar) async {
    final sync = ref.read(healthSyncProvider);
    await ref
        .read(selectedCalendarProvider.notifier)
        .choose(CalendarChoice(id: calendar.id, title: calendar.title));
    await sync.sync();
  }

  /// Arrête la synchronisation, sans toucher aux événements existants.
  Future<void> clear() => ref.read(selectedCalendarProvider.notifier).clear();
}
