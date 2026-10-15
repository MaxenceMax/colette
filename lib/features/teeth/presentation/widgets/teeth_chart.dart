import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart_painter.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Schéma interactif d'une dentition : deux arcades, une forme par dent.
class TeethChart extends StatelessWidget {
  const TeethChart({
    super.key,
    required this.dentition,
    required this.records,
    required this.onToothTap,
    this.selected,
  });

  /// Clé de la zone de dessin, pour viser une dent dans les tests.
  static const canvasKey = Key('teethChartCanvas');

  final Dentition dentition;
  final Map<ToothId, ToothRecord> records;
  final ValueChanged<ToothId> onToothTap;
  final ToothId? selected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final label = Theme.of(context).coletteTextStyles.small
        .copyWith(color: context.appColor(AppColors.textSecondary));
    final colors = (
      erupted: context.appColor(AppColors.primary),
      lostFill: context.appColor(AppColors.surfaceContainer),
      lostStroke: context.appColor(AppColors.border),
      mark: context.appColor(AppColors.textSecondary),
      absent: context.appColor(AppColors.textSecondary),
      selected: context.appColor(AppColors.onSurface),
    );
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.xs.value,
      children: [
        AspectRatio(
          aspectRatio: TeethLayout.aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = TeethLayout(dentition, constraints.biggest);
              return GestureDetector(
                behavior: .opaque,
                // Les dents portent leur propre action VoiceOver (peintre).
                excludeFromSemantics: true,
                onTapUp: (details) {
                  if (layout.hitTest(details.localPosition) case final id?) {
                    onToothTap(id);
                  }
                },
                child: CustomPaint(
                  key: canvasKey,
                  painter: TeethChartPainter(
                    layout: layout,
                    records: records,
                    selected: selected,
                    colors: colors,
                    labelOf: (id) => toothSemanticsLabel(id, records[id], s),
                    onToothTap: onToothTap,
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: TeethLayout.upperLabelAlignment,
                        child: Text(s.teethUpper, style: label),
                      ),
                      Align(
                        alignment: TeethLayout.lowerLabelAlignment,
                        child: Text(s.teethLower, style: label),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(s.teethRight, style: label),
            Text(s.teethLeft, style: label),
          ],
        ),
      ],
    );
  }
}
