import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_controller.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stock restant, recomptage, ajout de paquet et seuil d'alerte.
class DiaperStockSection extends ConsumerWidget {
  const DiaperStockSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final stock = ref.watch(diaperStockProvider).value;
    final status = ref.watch(diaperStockStatusProvider);
    // Restant fiable uniquement quand le comptage est chargé ; `null` désactive « + paquet ».
    final remaining = switch (status) {
      AsyncData(:final value) => value?.remaining ?? 0,
      _ => null,
    };
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.sm.all,
            child: switch (status) {
              AsyncData(value: null) => Text(
                s.diapersNotSet,
                style: styles.body.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
              ),
              AsyncData(value: final value?) => Text(
                s.diapersRemaining(value.remaining),
                style: styles.bodyMedium,
              ),
              AsyncError(:final error) => Text(
                failureMessage(error, s),
                style: styles.body.copyWith(
                  color: context.appColor(AppColors.error),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => showDiaperStockSheet(
                    context,
                    mode: DiaperStockSheetMode.recount,
                    current: stock,
                    remaining: remaining ?? 0,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(s.diapersRecount),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: remaining == null
                      ? null
                      : () => showDiaperStockSheet(
                          context,
                          mode: DiaperStockSheetMode.addPack,
                          current: stock,
                          remaining: remaining,
                        ),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(s.diapersAddPack),
                ),
              ),
            ],
          ),
          if (stock != null) _ThresholdStepper(stock: stock),
        ],
      ),
    );
  }
}

/// Stepper du seuil avec copie locale optimiste : des taps rapides s'enchaînent.
class _ThresholdStepper extends ConsumerStatefulWidget {
  const _ThresholdStepper({required this.stock});

  final DiaperStock stock;

  @override
  ConsumerState<_ThresholdStepper> createState() => _ThresholdStepperState();
}

class _ThresholdStepperState extends ConsumerState<_ThresholdStepper> {
  late int _threshold = widget.stock.alertThreshold;

  @override
  void didUpdateWidget(covariant _ThresholdStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.stock.alertThreshold;
    final writing = ref.read(diaperStockControllerProvider).isLoading;
    if (incoming != oldWidget.stock.alertThreshold && !writing) {
      _threshold = incoming;
    }
  }

  void _update(int next) {
    setState(() => _threshold = next);
    ref
        .read(diaperStockControllerProvider.notifier)
        .setThreshold(widget.stock, next);
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de setThreshold.
    ref.watch(diaperStockControllerProvider);
    return IntStepperRow(
      label: S.of(context).diapersAlertThreshold,
      value: _threshold,
      min: 0,
      max: 30,
      onChanged: _update,
    );
  }
}
