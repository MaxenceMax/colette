import 'dart:math';

import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:flutter/painting.dart';

/// Géométrie du schéma : position de chaque dent pour une dentition et une taille.
///
/// Vu de face : la droite de l'enfant est à gauche de l'écran. Chaque arcade est
/// une demi-ellipse ; l'arcade du bas est le reflet de celle du haut.
class TeethLayout {
  TeethLayout(this.dentition, this.size) : _rects = _compute(dentition, size);

  /// Largeur / hauteur du schéma.
  static const aspectRatio = 1 / 1.1;

  /// Libellé « Haut », au centre de l'arcade du haut.
  static const upperLabelAlignment = Alignment(0, -0.4);

  /// Libellé « Bas », au centre de l'arcade du bas.
  static const lowerLabelAlignment = Alignment(0, 0.4);

  // Demi-ellipses, en fractions de la largeur (X) et de la hauteur (Y).
  static const _radiusX = 0.40;
  static const _radiusY = 0.38;
  static const _baseY = 0.46;

  /// Part du quart d'ellipse occupée par les dents d'un côté.
  static const _sweep = pi / 2 * 0.92;

  final Dentition dentition;
  final Size size;
  final Map<ToothId, Rect> _rects;

  /// Rayon de tolérance au toucher (48 pt de diamètre) ; entre deux dents voisines, la plus proche l'emporte.
  static double get touchRadius => AppSize.xl.value / 2;

  /// Dents dans l'ordre du schéma.
  Iterable<ToothId> get teeth => _rects.keys;

  /// Rectangle englobant de [id], qui doit appartenir à [dentition].
  Rect rectOf(ToothId id) => _rects[id]!;

  /// Dent la plus proche de [point], si [point] est dans sa zone tactile.
  ToothId? hitTest(Offset point) {
    ToothId? nearest;
    var nearestDistance = double.infinity;
    for (final MapEntry(key: id, value: rect) in _rects.entries) {
      final distance = (rect.center - point).distance;
      final reach = max(rect.width / 2, touchRadius);
      if (distance <= reach && distance < nearestDistance) {
        nearest = id;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  static Map<ToothId, Rect> _compute(Dentition dentition, Size size) {
    final ids = ToothId.all(dentition);
    final perSide = ids.length ~/ 4;
    return {for (final id in ids) id: _rectOf(id, perSide, size)};
  }

  static Rect _rectOf(ToothId id, int perSide, Size size) {
    final angle = (id.position - 0.5) / perSide * _sweep;
    final direction = id.side == ToothSide.right ? -1.0 : 1.0;
    final x = size.width / 2 + direction * size.width * _radiusX * sin(angle);
    final upperY = size.height * (_baseY - _radiusY * cos(angle));
    final y = id.arch == ToothArch.upper ? upperY : size.height - upperY;
    return Rect.fromCircle(
      center: Offset(x, y),
      radius: size.width * _radiusFactor(id),
    );
  }

  /// Rayon d'une dent en fraction de la largeur : incisives petites, molaires grandes.
  static double _radiusFactor(ToothId id) => switch ((id.dentition, id.kind)) {
    (Dentition.primary, ToothKind.centralIncisor || ToothKind.lateralIncisor) =>
      0.040,
    (Dentition.primary, ToothKind.canine) => 0.045,
    (Dentition.primary, _) => 0.052,
    (
      Dentition.permanent,
      ToothKind.centralIncisor || ToothKind.lateralIncisor,
    ) =>
      0.028,
    (Dentition.permanent, ToothKind.canine) => 0.030,
    (
      Dentition.permanent,
      ToothKind.firstPremolar || ToothKind.secondPremolar,
    ) =>
      0.031,
    (Dentition.permanent, _) => 0.034,
  };

  @override
  bool operator ==(Object other) =>
      other is TeethLayout &&
      other.dentition == dentition &&
      other.size == size;

  @override
  int get hashCode => Object.hash(dentition, size);
}
