import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_legend.dart';
import 'package:colette/features/teeth/presentation/widgets/tooth_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Dents : schéma des dents de lait ou définitives, fiche au toucher.
class TeethPage extends ConsumerStatefulWidget {
  const TeethPage({super.key});

  @override
  ConsumerState<TeethPage> createState() => _TeethPageState();
}

class _TeethPageState extends ConsumerState<TeethPage> {
  var _dentition = Dentition.primary;

  /// Dent dont la fiche est ouverte, mise en évidence sur le schéma.
  ToothId? _selected;

  Future<void> _open(ToothId id, ToothRecord? record) async {
    setState(() => _selected = id);
    await showToothSheet(context, toothId: id, initial: record);
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.teethTitle)),
      body: switch (ref.watch(teethProvider)) {
        AsyncData(:final value) => _TeethBody(
          dentition: _dentition,
          records: value,
          selected: _selected,
          onDentitionChanged: (dentition) =>
              setState(() => _dentition = dentition),
          onToothTap: (id) => _open(id, value[id]),
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: AppSpacing.lg.all,
            child: Text(failureMessage(error, s), textAlign: .center),
          ),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TeethBody extends StatelessWidget {
  const _TeethBody({
    required this.dentition,
    required this.records,
    required this.selected,
    required this.onDentitionChanged,
    required this.onToothTap,
  });

  final Dentition dentition;
  final Map<ToothId, ToothRecord> records;
  final ToothId? selected;
  final ValueChanged<Dentition> onDentitionChanged;
  final ValueChanged<ToothId> onToothTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListView(
      padding: AppSpacing.md.all,
      children: [
        SegmentedButton<Dentition>(
          segments: [
            ButtonSegment(
              value: Dentition.primary,
              label: Text(s.teethPrimary),
            ),
            ButtonSegment(
              value: Dentition.permanent,
              label: Text(s.teethPermanent),
            ),
          ],
          selected: {dentition},
          onSelectionChanged: (selection) =>
              onDentitionChanged(selection.single),
        ),
        AppSpacing.md.verticalSpace,
        Text(
          teethCounterLabel(dentition, records, s),
          style: Theme.of(context).coletteTextStyles.body
              .copyWith(color: context.appColor(AppColors.textSecondary)),
        ),
        AppSpacing.md.verticalSpace,
        TeethChart(
          dentition: dentition,
          records: records,
          selected: selected,
          onToothTap: onToothTap,
        ),
        AppSpacing.lg.verticalSpace,
        const TeethLegend(),
      ],
    );
  }
}
