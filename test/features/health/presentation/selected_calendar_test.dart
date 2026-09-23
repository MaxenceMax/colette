import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('choix mémorisé dans les préférences puis effacé', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(selectedCalendarProvider), isNull);

    await container
        .read(selectedCalendarProvider.notifier)
        .choose(const CalendarChoice(id: 'c1', title: 'Famille'));
    expect(
      container.read(selectedCalendarProvider),
      const CalendarChoice(id: 'c1', title: 'Famille'),
    );
    expect(prefs.getString(SelectedCalendar.idKey), 'c1');

    await container.read(selectedCalendarProvider.notifier).clear();
    expect(container.read(selectedCalendarProvider), isNull);
    expect(prefs.getString(SelectedCalendar.idKey), isNull);
  });
}
