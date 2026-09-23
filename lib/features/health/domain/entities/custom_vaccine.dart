import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_vaccine.freezed.dart';

/// Injection reçue lors d'un RDV libre : vaccin connu ([code]) ou à nom
/// libre ([name]), exactement l'un des deux.
@freezed
abstract class CustomVaccine with _$CustomVaccine {
  const CustomVaccine._();

  const factory CustomVaccine({
    VaccineCode? code,
    String? name,
    required DateTime givenAt,
    String? brand,
    String? lot,
  }) = _CustomVaccine;

  bool get isKnown => code != null;
}
