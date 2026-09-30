import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipient.freezed.dart';

/// Proche qui reçoit les photos : nom affiché et numéro choisi dans les contacts.
@freezed
abstract class Recipient with _$Recipient {
  const factory Recipient({required String name, required String phone}) =
      _Recipient;
}
