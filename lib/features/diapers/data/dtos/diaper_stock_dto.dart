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
      count: _readInt(map, 'count', 0, min: 0, max: DiaperStock.maxCount),
      countedAt: countedAt.toDate(),
      alertThreshold: _readInt(
        map,
        'alertThreshold',
        DiaperStock.defaultAlertThreshold,
        min: 0,
        max: DiaperStock.maxThreshold,
      ),
      lastPackSize: _readInt(
        map,
        'lastPackSize',
        DiaperStock.defaultPackSize,
        min: 1,
        max: DiaperStock.maxPackSize,
      ),
    );
  }
}
