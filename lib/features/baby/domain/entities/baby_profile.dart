import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_profile.freezed.dart';

/// Profil du bébé.
@freezed
abstract class BabyProfile with _$BabyProfile {
  const factory BabyProfile({
    required String name,
    required DateTime birthDate,
    DateTime? cordFallenAt,
    @Default(CareSettings()) CareSettings careSettings,
  }) = _BabyProfile;
}
