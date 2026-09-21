import 'package:freezed_annotation/freezed_annotation.dart';

part 'household.freezed.dart';

/// Un foyer, identifié par son code.
@freezed
abstract class Household with _$Household {
  const factory Household({required String code, required DateTime createdAt}) =
      _Household;
}
