import 'package:freezed_annotation/freezed_annotation.dart';

part 'diaper_stock.freezed.dart';

/// Stock de couches : `count` couches comptées à l'instant `countedAt`.
@freezed
abstract class DiaperStock with _$DiaperStock {
  const DiaperStock._();

  static const defaultPackSize = 44;
  static const defaultAlertThreshold = 10;
  static const maxCount = 9999;
  static const maxPackSize = 999;
  static const maxThreshold = 999;

  const factory DiaperStock({
    required int count,
    required DateTime countedAt,
    @Default(DiaperStock.defaultAlertThreshold) int alertThreshold,
    @Default(DiaperStock.defaultPackSize) int lastPackSize,
  }) = _DiaperStock;

  /// Nouveau comptage à [now] ; seuil et taille de paquet conservés.
  DiaperStock recount(int count, {required DateTime now}) =>
      copyWith(count: count, countedAt: now);

  /// Ajoute un paquet de [size] couches au [remaining] courant, à [now].
  DiaperStock addPack(
    int size, {
    required int remaining,
    required DateTime now,
  }) => copyWith(count: remaining + size, countedAt: now, lastPackSize: size);
}
