import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';

/// Conversion `WeightEntry` ↔ document `weights/{id}`.
abstract final class WeightEntryDto {
  static Map<String, dynamic> toMap(WeightEntry entry) => {
    'measuredAt': Timestamp.fromDate(entry.measuredAt),
    'grams': entry.grams,
  };

  static WeightEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WeightEntry(
      id: doc.id,
      measuredAt: (data['measuredAt'] as Timestamp).toDate(),
      grams: (data['grams'] as num).toInt(),
    );
  }
}
