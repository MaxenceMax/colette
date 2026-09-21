import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Conversion `CareEvent` ↔ document `events/{id}`.
abstract final class CareEventDto {
  static Map<String, dynamic> toMap(CareEvent event) => {
    'startAt': Timestamp.fromDate(event.startAt),
    'endAt': Timestamp.fromDate(event.endAt),
    'pee': event.pee,
    'poop': event.poop,
    'diaperChange': event.diaperChange,
    'adrigyl': event.adrigyl,
    'bath': event.bath,
    'eyeCare': event.eyeCare,
    'noseCare': event.noseCare,
    'umbilicalCare': event.umbilicalCare,
    'bottleMl': event.bottleMl,
    'hasBottle': event.hasBottle,
    'note': event.note,
    'createdByDeviceId': event.createdByDeviceId,
    'createdAt': Timestamp.fromDate(event.createdAt),
    'updatedAt': Timestamp.fromDate(event.updatedAt),
  };

  static CareEvent fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CareEvent(
      id: doc.id,
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp).toDate(),
      pee: data['pee'] as bool? ?? false,
      poop: data['poop'] as bool? ?? false,
      diaperChange: data['diaperChange'] as bool? ?? false,
      adrigyl: data['adrigyl'] as bool? ?? false,
      bath: data['bath'] as bool? ?? false,
      eyeCare: data['eyeCare'] as bool? ?? false,
      noseCare: data['noseCare'] as bool? ?? false,
      umbilicalCare: data['umbilicalCare'] as bool? ?? false,
      bottleMl: (data['bottleMl'] as num?)?.toInt(),
      note: data['note'] as String?,
      createdByDeviceId: data['createdByDeviceId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
