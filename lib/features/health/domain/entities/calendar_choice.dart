import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_choice.freezed.dart';

/// Calendrier choisi sur cet iPhone pour les RDV santé.
@freezed
abstract class CalendarChoice with _$CalendarChoice {
  const factory CalendarChoice({required String id, required String title}) =
      _CalendarChoice;
}
