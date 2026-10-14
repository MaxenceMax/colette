import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const sizes = [Size(300, 330), Size(390, 429)];

  for (final dentition in Dentition.values) {
    for (final size in sizes) {
      test('$dentition $size : dents séparées et dans le cadre', () {
        final layout = TeethLayout(dentition, size);
        final rects = [for (final id in layout.teeth) layout.rectOf(id)];
        expect(rects, hasLength(ToothId.all(dentition).length));
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final a = rects[i];
            final b = rects[j];
            expect(
              (a.center - b.center).distance,
              greaterThanOrEqualTo(a.width / 2 + b.width / 2),
              reason: 'dents $i et $j',
            );
          }
        }
        final frame = Offset.zero & size;
        for (final rect in rects) {
          expect(frame.contains(rect.topLeft), isTrue);
          expect(frame.contains(rect.bottomRight), isTrue);
        }
      });

      test('$dentition $size : toucher le centre d\'une dent la désigne', () {
        final layout = TeethLayout(dentition, size);
        for (final id in layout.teeth) {
          expect(layout.hitTest(layout.rectOf(id).center), id);
        }
        expect(layout.hitTest(size.center(Offset.zero)), isNull);
      });
    }
  }

  test('vu de face : symétrie droite/gauche et haut/bas', () {
    const size = Size(390, 429);
    final layout = TeethLayout(Dentition.primary, size);
    final upperRight = layout.rectOf(tooth(51)).center;
    final upperLeft = layout.rectOf(tooth(61)).center;
    final lowerRight = layout.rectOf(tooth(81)).center;
    // La droite de l'enfant est à gauche de l'écran.
    expect(upperRight.dx, lessThan(size.width / 2));
    expect(upperRight.dx, closeTo(size.width - upperLeft.dx, 1e-9));
    expect(upperRight.dy, closeTo(upperLeft.dy, 1e-9));
    expect(lowerRight.dy, closeTo(size.height - upperRight.dy, 1e-9));
    expect(lowerRight.dx, closeTo(upperRight.dx, 1e-9));
  });

  test('zone tactile élargie autour d\'une petite dent', () {
    const size = Size(390, 429);
    final layout = TeethLayout(Dentition.permanent, size);
    final incisor = layout.rectOf(tooth(11));
    final justOutside = incisor.center.translate(0, -(incisor.height / 2 + 4));
    expect(layout.hitTest(justOutside), tooth(11));
  });

  test('entre deux dents voisines, la plus proche l\'emporte', () {
    final layout = TeethLayout(Dentition.permanent, const Size(343, 377.3));
    final a = layout.rectOf(tooth(11)).center;
    final b = layout.rectOf(tooth(12)).center;
    expect(layout.hitTest(Offset.lerp(a, b, 0.4)!), tooth(11));
    expect(layout.hitTest(Offset.lerp(a, b, 0.6)!), tooth(12));
  });

  test('égalité selon la dentition et la taille', () {
    const size = Size(390, 429);
    final layout = TeethLayout(Dentition.primary, size);
    final same = TeethLayout(Dentition.primary, size);
    final other = TeethLayout(Dentition.permanent, size);
    expect(layout, same);
    expect(layout.hashCode, same.hashCode);
    expect(layout, isNot(other));
  });
}
