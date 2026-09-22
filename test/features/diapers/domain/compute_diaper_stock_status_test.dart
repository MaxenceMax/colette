import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/use_cases/compute_diaper_stock_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeDiaperStockStatus();
  final countedAt = DateTime(2026, 9, 20, 10);

  test('restant = count − changes depuis le comptage', () {
    final status = compute(
      stock: DiaperStock(count: 44, countedAt: countedAt),
      changesSinceCount: 4,
    );
    expect(status.remaining, 40);
    expect(status.isLow, isFalse);
  });

  test('le restant est borné à 0', () {
    final status = compute(
      stock: DiaperStock(count: 3, countedAt: countedAt),
      changesSinceCount: 5,
    );
    expect(status.remaining, 0);
    expect(status.isLow, isTrue);
  });

  test('isLow est vrai strictement sous le seuil, faux au seuil', () {
    final stock = DiaperStock(count: 10, countedAt: countedAt);
    expect(compute(stock: stock, changesSinceCount: 0).isLow, isFalse);
    expect(compute(stock: stock, changesSinceCount: 1).isLow, isTrue);
  });

  test('un seuil à 0 désactive l\'alerte', () {
    final status = compute(
      stock: DiaperStock(count: 2, countedAt: countedAt, alertThreshold: 0),
      changesSinceCount: 2,
    );
    expect(status.remaining, 0);
    expect(status.isLow, isFalse);
  });
}
