import 'package:freezed_annotation/freezed_annotation.dart';

part 'diaper_stock_status.freezed.dart';

/// Stock restant et signal d'alerte.
@freezed
abstract class DiaperStockStatus with _$DiaperStockStatus {
  const factory DiaperStockStatus({
    required int remaining,
    required bool isLow,
  }) = _DiaperStockStatus;
}
