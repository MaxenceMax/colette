import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Conversion `SleepSession` ↔ document `sleeps/{id}`.
abstract final class SleepSessionDto {
  /// `endAt` est toujours écrit, à `null` pour un sommeil en cours.
  static Map<String, dynamic> toMap(SleepSession session) => {
    'startAt': Timestamp.fromDate(session.startAt),
    'endAt': switch (session.endAt) {
      null => null,
      final end => Timestamp.fromDate(end),
    },
    'kind': session.kind.name,
    'createdByDeviceId': session.createdByDeviceId,
    'createdAt': Timestamp.fromDate(session.createdAt),
    'updatedAt': Timestamp.fromDate(session.updatedAt),
  };

  /// `kind` inconnu → sieste.
  static SleepSession fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SleepSession(
      id: doc.id,
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp?)?.toDate(),
      kind:
          SleepKind.values.where((k) => k.name == data['kind']).firstOrNull ??
          SleepKind.nap,
      createdByDeviceId: data['createdByDeviceId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
