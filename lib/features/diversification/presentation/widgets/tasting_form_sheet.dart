import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/use_cases/check_tasting_warnings.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/tasting_form_controller.dart';
import 'package:colette/features/diversification/presentation/widgets/food_picker_sheet.dart';
import 'package:colette/features/diversification/presentation/widgets/rule_tile.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_warnings_dialog.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la saisie d'une dégustation ; [tasting] renseignée pour la modifier.
Future<void> showTastingFormSheet(
  BuildContext context, {
  Food? food,
  Tasting? tasting,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => TastingFormSheet(food: food, tasting: tasting),
);

/// Aliment, moment, appréciation, réaction et note d'une dégustation.
class TastingFormSheet extends ConsumerStatefulWidget {
  const TastingFormSheet({super.key, this.food, this.tasting});

  final Food? food;
  final Tasting? tasting;

  @override
  ConsumerState<TastingFormSheet> createState() => _TastingFormSheetState();
}

class _TastingFormSheetState extends ConsumerState<TastingFormSheet> {
  static const _maxNoteLength = 500;

  late Food? _food = widget.food;
  late DateTime _at;
  late Liking? _liking = widget.tasting?.liking;
  late bool _hadReaction = widget.tasting?.hadReaction ?? false;
  late final TextEditingController _note = TextEditingController(
    text: widget.tasting?.note ?? '',
  );
  bool _missingFood = false;

  /// `true` dès que cette feuille a tenté un enregistrement : évite d'afficher
  /// un échec ou un chargement laissés par une utilisation précédente du
  /// contrôleur `autoDispose` (partagé entre les ouvertures successives).
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _at = widget.tasting?.at ?? ref.read(clockProvider).now();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickFood() async {
    final food = await showFoodPickerSheet(context);
    if (food == null || !mounted) return;
    setState(() {
      _food = food;
      _missingFood = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _at,
      mode: CupertinoDatePickerMode.dateAndTime,
      maximum: ref.read(clockProvider).now(),
      minimum: ref.read(babyProfileProvider).value?.birthDate,
    );
    if (picked != null && mounted) setState(() => _at = picked);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final food = _food;
    if (food == null) {
      setState(() => _missingFood = true);
      return;
    }
    final warnings = const CheckTastingWarnings()(
      food: food,
      at: _at,
      birthDate: ref.read(babyProfileProvider).value?.birthDate,
    );
    if (warnings.isNotEmpty) {
      final confirmed = await showTastingWarningsDialog(context, warnings);
      if (!confirmed || !mounted) return;
    }
    final ok = await ref
        .read(tastingFormControllerProvider.notifier)
        .save(
          Tasting(
            id: widget.tasting?.id ?? '',
            foodId: food.id,
            at: _at,
            liking: _liking,
            hadReaction: _hadReaction,
            note: _note.text,
          ),
        );
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de _save.
    final saveState = ref.watch(tastingFormControllerProvider);
    // Gardé à l'écoute : `_save` et `_pickDate` y lisent la date de
    // naissance (avertissements, borne basse du sélecteur de date).
    ref.watch(babyProfileProvider);
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final errorColor = context.appColor(AppColors.error);
    final food = _food;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            widget.tasting == null ? s.tastingNewTitle : s.tastingEditTitle,
            style: styles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          _PickerField(
            label: s.tastingFieldFood,
            value: food == null
                ? s.tastingChooseFood
                : foodDisplayName(food, s),
            onTap: widget.tasting == null ? _pickFood : null,
          ),
          if (_missingFood)
            Text(
              s.tastingFoodRequired,
              style: styles.small.copyWith(color: errorColor),
            ),
          if (food != null) _FoodRulesSection(food: food, at: _at),
          AppSpacing.md.verticalSpace,
          _PickerField(
            label: s.tastingFieldWhen,
            value: formatDayAndTime(_at),
            onTap: _pickDate,
          ),
          AppSpacing.md.verticalSpace,
          Text(s.tastingFieldLiking, style: styles.label),
          AppSpacing.xs.verticalSpace,
          SegmentedButton<Liking>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: [
              for (final liking in Liking.values)
                ButtonSegment(value: liking, label: Text(liking.label(s))),
            ],
            selected: {?_liking},
            onSelectionChanged: (selection) =>
                setState(() => _liking = selection.firstOrNull),
          ),
          AppSpacing.md.verticalSpace,
          Text(s.tastingFieldReaction, style: styles.label),
          AppSpacing.xs.verticalSpace,
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(s.tastingReactionNone)),
              ButtonSegment(
                value: true,
                label: Text(s.tastingReactionObserved),
              ),
            ],
            selected: {_hadReaction},
            onSelectionChanged: (selection) =>
                setState(() => _hadReaction = selection.first),
          ),
          if (_hadReaction)
            Padding(
              padding: AppSpacing.sm.top,
              child: Text(
                s.tastingEmergency,
                style: styles.body.copyWith(color: errorColor),
              ),
            ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: s.tastingFieldNote),
            maxLength: _maxNoteLength,
            minLines: 1,
            maxLines: 3,
          ),
          if (saveState case AsyncError(:final error) when _submitted)
            Text(
              failureMessage(error, s),
              style: styles.body.copyWith(color: errorColor),
            ),
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: _submitted && saveState is AsyncLoading ? null : _save,
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
  }
}

/// Champ cliquable : libellé au-dessus, valeur, chevron.
class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return ColetteCardSurface(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(label, style: styles.small.copyWith(color: secondary)),
                Text(value, style: styles.body),
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, color: secondary),
        ],
      ),
    );
  }
}

/// Allergènes et règles actives de l'aliment choisi, à l'âge du bébé à la
/// date de la dégustation ; masqué si rien à montrer.
class _FoodRulesSection extends ConsumerWidget {
  const _FoodRulesSection({required this.food, required this.at});

  final Food food;

  /// Date de la dégustation, pour calculer l'âge des règles à cette date.
  final DateTime at;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final birthDate = ref.watch(babyProfileProvider).value?.birthDate;
    final ageMonths = birthDate == null
        ? null
        : completedMonthsBetween(birthDate, at);
    final visibleRules = [
      for (final rule in food.rules)
        if (rule.kind == RuleKind.info ||
            ageMonths == null ||
            rule.isActiveAt(ageMonths))
          rule,
    ];
    if (food.allergens.isEmpty && visibleRules.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: AppSpacing.sm.top,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.appColor(AppColors.border)),
          borderRadius: AppRadius.md.circular,
        ),
        child: Padding(
          padding: AppSpacing.sm.all,
          child: Column(
            crossAxisAlignment: .start,
            children: [
              if (food.allergens.isNotEmpty)
                Text(
                  s.tastingAllergens(
                    food.allergens
                        .map((allergen) => allergen.label(s))
                        .join(', '),
                  ),
                  style: Theme.of(context).coletteTextStyles.label
                      .copyWith(color: context.appColor(AppColors.warning)),
                ),
              for (final rule in visibleRules) RuleTile(rule: rule),
            ],
          ),
        ),
      ),
    );
  }
}
