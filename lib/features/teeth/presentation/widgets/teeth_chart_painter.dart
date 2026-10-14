import 'dart:math';

import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/entities/tooth_status.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_tooth_status.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Couleurs du schéma, résolues selon le thème.
typedef TeethChartColors = ({
  Color erupted,
  Color lostFill,
  Color lostStroke,
  Color mark,
  Color absent,
  Color selected,
});

/// Dessine les dents selon leur état ; une zone VoiceOver par dent.
class TeethChartPainter extends CustomPainter {
  TeethChartPainter({
    required this.layout,
    required this.records,
    required this.selected,
    required this.colors,
    required this.labelOf,
    required this.onToothTap,
  });

  final TeethLayout layout;
  final Map<ToothId, ToothRecord> records;
  final ToothId? selected;
  final TeethChartColors colors;
  final String Function(ToothId) labelOf;
  final ValueChanged<ToothId> onToothTap;

  @override
  void paint(Canvas canvas, Size size) {
    const status = ComputeToothStatus();
    final strokeWidth = AppStroke.regular.value;
    final selectionWidth = AppStroke.thick.value;
    for (final id in layout.teeth) {
      final rect = layout.rectOf(id);
      // Les traits restent à l'intérieur de la dent : les molaires
      // permanentes ne sont espacées que de quelques points.
      final oval = Path()..addOval(rect.deflate(strokeWidth / 2));
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      switch (status(records[id])) {
        case ToothStatus.erupted:
          canvas.drawOval(rect, Paint()..color = colors.erupted);
        case ToothStatus.lost:
          canvas
            ..drawOval(rect, Paint()..color = colors.lostFill)
            ..drawPath(oval, stroke..color = colors.lostStroke);
          _drawCross(canvas, rect, strokeWidth);
        case ToothStatus.absent:
          canvas.drawPath(_dashed(oval), stroke..color = colors.absent);
      }
      if (id == selected) {
        canvas.drawPath(
          Path()..addOval(rect.deflate(selectionWidth / 2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = selectionWidth
            ..color = colors.selected,
        );
      }
    }
  }

  void _drawCross(Canvas canvas, Rect rect, double strokeWidth) {
    final inner = rect.deflate(rect.width / 4);
    final paint = Paint()
      ..color = colors.mark
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(inner.topLeft, inner.bottomRight, paint)
      ..drawLine(inner.topRight, inner.bottomLeft, paint);
  }

  /// Contour pointillé de [source] : traits et blancs de même longueur.
  static Path _dashed(Path source) {
    final dash = AppSpacing.xs.value;
    final result = Path();
    for (final metric in source.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += dash * 2) {
        result.addPath(
          metric.extractPath(start, min(start + dash, metric.length)),
          Offset.zero,
        );
      }
    }
    return result;
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final id in layout.teeth)
          CustomPainterSemantics(
            key: ValueKey(id.value),
            rect: layout.rectOf(id),
            properties: SemanticsProperties(
              label: labelOf(id),
              textDirection: TextDirection.ltr,
              button: true,
              selected: id == selected,
              onTap: () => onToothTap(id),
            ),
          ),
      ];

  bool _differs(TeethChartPainter old) =>
      old.layout != layout ||
      !mapEquals(old.records, records) ||
      old.selected != selected;

  @override
  bool shouldRepaint(TeethChartPainter oldDelegate) =>
      _differs(oldDelegate) || oldDelegate.colors != colors;

  @override
  bool shouldRebuildSemantics(TeethChartPainter oldDelegate) =>
      _differs(oldDelegate);
}
