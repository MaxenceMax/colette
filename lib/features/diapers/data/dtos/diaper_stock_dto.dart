import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';

/// Conversion `DiaperStock` ↔ champ `diaperStock` du document foyer.
abstract final class DiaperStockDto {
  static Map<String, dynamic> toMap(DiaperStock stock) => {
    'count': stock.count,
    'countedAt': Timestamp.fromDate(stock.countedAt),
    'alertThreshold': stock.alertThreshold,
    'lastPackSize': stock.lastPackSize,
  };

  static int _readInt(
    Map<String, dynamic> map,
    String key,
    int fallback, {
    required int min,
    required int max,
  }) => ((map[key] as num?)?.toInt() ?? fallback).clamp(min, max);

  /// `null` sans `countedAt` valide : stock non renseigné. Valeurs bornées.
  static DiaperStock? fromMap(Map<String, dynamic> map) {
    final countedAt = map['countedAt'];
    if (countedAt is! Timestamp) return null;
    return DiaperStock(
      count: _readInt(map, 'count', 0, min: 0, max: 9999),
      countedAt: countedAt.toDate(),
      alertThreshold: _readInt(map, 'alertThreshold', 10, min: 0, max: 999),
      lastPackSize: _readInt(map, 'lastPackSize', 44, min: 1, max: 999),
    );
  }
}
