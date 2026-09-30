import 'dart:convert';

import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';

/// Conversion des listes de diffusion ↔ JSON local.
abstract final class BroadcastListDto {
  static String encode(List<BroadcastList> lists) => jsonEncode([
    for (final list in lists)
      {
        'id': list.id,
        'name': list.name,
        'recipients': [
          for (final r in list.recipients) {'name': r.name, 'phone': r.phone},
        ],
        if (list.lastSentAt case final sentAt?)
          'lastSentAt': sentAt.millisecondsSinceEpoch,
      },
  ]);

  /// Lève une exception si [raw] est illisible (convertie par `guard()`).
  static List<BroadcastList> decode(String raw) => [
    for (final item in jsonDecode(raw) as List<dynamic>)
      _list(item as Map<String, dynamic>),
  ];

  static BroadcastList _list(Map<String, dynamic> map) => BroadcastList(
    id: map['id'] as String,
    name: map['name'] as String,
    recipients: [
      for (final r in map['recipients'] as List<dynamic>)
        _recipient(r as Map<String, dynamic>),
    ],
    lastSentAt: switch (map['lastSentAt'] as int?) {
      final ms? => DateTime.fromMillisecondsSinceEpoch(ms),
      null => null,
    },
  );

  static Recipient _recipient(Map<String, dynamic> map) =>
      Recipient(name: map['name'] as String, phone: map['phone'] as String);
}
