import 'package:colette/features/health/domain/entities/custom_vaccine.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_appointment.freezed.dart';

/// Rendez-vous hors calendrier de référence : titre libre, date obligatoire,
/// praticien, visite faite, note et injections reçues.
@freezed
abstract class CustomAppointment with _$CustomAppointment {
  const factory CustomAppointment({
    required String id,
    required String title,
    required DateTime appointmentAt,
    String? practitioner,
    DateTime? doneAt,
    String? note,
    @Default(<CustomVaccine>[]) List<CustomVaccine> vaccines,
    required DateTime updatedAt,
    required String updatedByDeviceId,
  }) = _CustomAppointment;
}
