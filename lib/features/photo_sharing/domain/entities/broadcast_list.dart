import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/normalize_phone.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'broadcast_list.freezed.dart';

/// Liste de diffusion : un nom et les proches qui reçoivent chacun un message.
@freezed
abstract class BroadcastList with _$BroadcastList {
  const BroadcastList._();

  const factory BroadcastList({
    required String id,
    required String name,
    required List<Recipient> recipients,
  }) = _BroadcastList;

  /// Ajoute [recipient], sauf si son numéro (normalisé) est déjà présent.
  BroadcastList withRecipient(Recipient recipient) {
    final phone = normalizePhone(recipient.phone);
    if (recipients.any((r) => normalizePhone(r.phone) == phone)) return this;
    return copyWith(recipients: [...recipients, recipient]);
  }

  /// Retire la personne dont le numéro est exactement [phone].
  BroadcastList withoutRecipient(String phone) => copyWith(
    recipients: [
      for (final r in recipients)
        if (r.phone != phone) r,
    ],
  );
}
