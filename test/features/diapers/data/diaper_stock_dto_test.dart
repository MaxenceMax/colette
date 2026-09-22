import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/diapers/data/dtos/diaper_stock_dto.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final countedAt = DateTime(2026, 9, 20, 10);

  test('aller-retour toMap / fromMap', () {
    final stock = DiaperStock(
      count: 44,
      countedAt: countedAt,
      alertThreshold: 8,
      lastPackSize: 30,
    );
    expect(DiaperStockDto.fromMap(DiaperStockDto.toMap(stock)), stock);
  });

  test('toMap écrit countedAt en Timestamp', () {
    final map = DiaperStockDto.toMap(
      DiaperStock(count: 1, countedAt: countedAt),
    );
    expect(map['countedAt'], Timestamp.fromDate(countedAt));
  });

  test('fromMap renvoie null sans countedAt', () {
    expect(DiaperStockDto.fromMap(const {'count': 44}), isNull);
  });

  test('fromMap applique les défauts et borne les valeurs', () {
    final stock = DiaperStockDto.fromMap({
      'count': 99999,
      'countedAt': Timestamp.fromDate(countedAt),
      'lastPackSize': 0,
    })!;
    expect(stock.count, 9999);
    expect(stock.alertThreshold, 10);
    expect(stock.lastPackSize, 1);
  });
}
