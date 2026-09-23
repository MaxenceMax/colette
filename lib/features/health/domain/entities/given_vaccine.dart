import 'package:freezed_annotation/freezed_annotation.dart';

part 'given_vaccine.freezed.dart';

/// Injection reçue : date, nom commercial et numéro de lot facultatifs.
@freezed
abstract class GivenVaccine with _$GivenVaccine {
  const factory GivenVaccine({
    required DateTime givenAt,
    String? brand,
    String? lot,
  }) = _GivenVaccine;
}
