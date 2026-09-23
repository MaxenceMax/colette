import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';

/// Conversion `GrowthMeasurement` ↔ document `weights/{id}` ; les valeurs
/// absentes ne sont pas écrites.
abstract final class GrowthMeasurementDto {
  static Map<String, dynamic> toMap(GrowthMeasurement m) => {
    'measuredAt': Timestamp.fromDate(m.measuredAt),
    'grams': ?m.grams,
    'lengthMm': ?m.lengthMm,
    'headCircumferenceMm': ?m.headCircumferenceMm,
  };

  static GrowthMeasurement fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GrowthMeasurement(
      id: doc.id,
      measuredAt: (data['measuredAt'] as Timestamp).toDate(),
      grams: (data['grams'] as num?)?.toInt(),
      lengthMm: (data['lengthMm'] as num?)?.toInt(),
      headCircumferenceMm: (data['headCircumferenceMm'] as num?)?.toInt(),
    );
  }
}
