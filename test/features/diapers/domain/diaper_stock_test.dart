import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final countedAt = DateTime(2026, 9, 20, 10);
  final now = DateTime(2026, 9, 22, 15);
  final stock = DiaperStock(
    count: 44,
    countedAt: countedAt,
    alertThreshold: 12,
    lastPackSize: 30,
  );

  test('les défauts sont seuil 10 et paquet 44', () {
    final fresh = DiaperStock(count: 0, countedAt: countedAt);
    expect(fresh.alertThreshold, 10);
    expect(fresh.lastPackSize, 44);
  });

  test('recount pose count et countedAt, conserve seuil et paquet', () {
    final next = stock.recount(20, now: now);
    expect(next.count, 20);
    expect(next.countedAt, now);
    expect(next.alertThreshold, 12);
    expect(next.lastPackSize, 30);
  });

  test('addPack ajoute au restant, pose countedAt et mémorise la taille', () {
    final next = stock.addPack(50, remaining: 7, now: now);
    expect(next.count, 57);
    expect(next.countedAt, now);
    expect(next.lastPackSize, 50);
    expect(next.alertThreshold, 12);
  });
}
