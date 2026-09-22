import 'dart:math' as math;

import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';

/// Restant = `count − changes depuis countedAt`, borné à 0.
/// Alerte si le seuil est actif (> 0) et que le restant lui est strictement inférieur.
class ComputeDiaperStockStatus {
  const ComputeDiaperStockStatus();

  DiaperStockStatus call({
    required DiaperStock stock,
    required int changesSinceCount,
  }) {
    final remaining = math.max(0, stock.count - changesSinceCount);
    return DiaperStockStatus(
      remaining: remaining,
      isLow: stock.alertThreshold > 0 && remaining < stock.alertThreshold,
    );
  }
}
