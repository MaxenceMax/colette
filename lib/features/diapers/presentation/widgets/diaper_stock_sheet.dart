import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ce que la feuille enregistre : un nouveau comptage ou un paquet ajouté.
enum DiaperStockSheetMode { recount, addPack }

/// Ouvre la saisie du stock. [current] est `null` tant que le stock n'est pas renseigné.
Future<void> showDiaperStockSheet(
  BuildContext context, {
  required DiaperStockSheetMode mode,
  required DiaperStock? current,
  required int remaining,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      DiaperStockSheet(mode: mode, current: current, remaining: remaining),
);

/// Un champ numérique et un bouton, en mode recomptage ou ajout de paquet.
class DiaperStockSheet extends ConsumerStatefulWidget {
  const DiaperStockSheet({
    super.key,
    required this.mode,
    required this.current,
    required this.remaining,
  });

  final DiaperStockSheetMode mode;
  final DiaperStock? current;
  final int remaining;

  @override
  ConsumerState<DiaperStockSheet> createState() => _DiaperStockSheetState();
}

class _DiaperStockSheetState extends ConsumerState<DiaperStockSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: switch (widget.mode) {
      DiaperStockSheetMode.recount => '',
      DiaperStockSheetMode.addPack => '${widget.current?.lastPackSize ?? 44}',
    },
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = int.tryParse(_controller.text.trim()) ?? -1;
    final controller = ref.read(diaperStockControllerProvider.notifier);
    final ok = switch (widget.mode) {
      DiaperStockSheetMode.recount => await controller.recount(
        widget.current,
        value,
      ),
      DiaperStockSheetMode.addPack => await controller.addPack(
        widget.current,
        remaining: widget.remaining,
        size: value,
      ),
    };
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de _save.
    ref.watch(diaperStockControllerProvider);
    final s = S.of(context);
    final (title, action) = switch (widget.mode) {
      DiaperStockSheetMode.recount => (s.diapersRecountTitle, s.actionSave),
      DiaperStockSheetMode.addPack => (s.diapersAddPackTitle, s.actionAdd),
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(title, style: Theme.of(context).coletteTextStyles.heading2),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: s.fieldDiaperCount),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          AppSpacing.lg.verticalSpace,
          FilledButton(onPressed: _save, child: Text(action)),
        ],
      ),
    );
  }
}
