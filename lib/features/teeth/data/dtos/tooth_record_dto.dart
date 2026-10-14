import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';

/// Conversion `ToothRecord` ↔ document `teeth/{numéro}` ; clés absentes plutôt que nulles.
abstract final class ToothRecordDto {
  /// Identifiant du document de [id].
  static String docId(ToothId id) => '${id.value}';

  static Map<String, dynamic> toMap(ToothRecord r) => {
    if (r.eruptedAt case final at?) 'eruptedAt': Timestamp.fromDate(at),
    if (r.lostAt case final at?) 'lostAt': Timestamp.fromDate(at),
    'note': ?r.note,
    'updatedAt': Timestamp.fromDate(r.updatedAt),
    'updatedByDeviceId': r.updatedByDeviceId,
  };

  /// `null` pour un numéro inconnu ou un document illisible (`updatedAt` absent).
  static ToothRecord? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final toothId = switch (int.tryParse(doc.id)) {
      final number? => ToothId.tryParse(number),
      null => null,
    };
    final data = doc.data();
    if (toothId == null || data == null) return null;
    if (data['updatedAt'] is! Timestamp) return null;
    return ToothRecord(
      toothId: toothId,
      eruptedAt: switch (data['eruptedAt']) {
        final Timestamp t => t.toDate(),
        _ => null,
      },
      lostAt: switch (data['lostAt']) {
        final Timestamp t => t.toDate(),
        _ => null,
      },
      note: switch (data['note']) {
        final String n => n,
        _ => null,
      },
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      updatedByDeviceId: data['updatedByDeviceId'] as String? ?? '',
    );
  }
}
