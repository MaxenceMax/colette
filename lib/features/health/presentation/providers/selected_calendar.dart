import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_calendar.g.dart';

/// Calendrier des RDV santé de cet iPhone (identifiants EventKit propres à l'appareil).
@Riverpod(keepAlive: true)
class SelectedCalendar extends _$SelectedCalendar {
  static const idKey = 'health_calendar_id';
  static const titleKey = 'health_calendar_title';

  @override
  CalendarChoice? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final id = prefs.getString(idKey);
    final title = prefs.getString(titleKey);
    return id == null || title == null
        ? null
        : CalendarChoice(id: id, title: title);
  }

  Future<void> choose(CalendarChoice choice) async {
    state = choice;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(idKey, choice.id);
    await prefs.setString(titleKey, choice.title);
  }

  Future<void> clear() async {
    state = null;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(idKey);
    await prefs.remove(titleKey);
  }
}
