import 'package:freezed_annotation/freezed_annotation.dart';

part 'pediatrician_advice.freezed.dart';

/// Consigne du pédiatre, avec ses précisions en sous-liste.
@freezed
abstract class AdviceItem with _$AdviceItem {
  const factory AdviceItem({
    required String text,
    @Default(<String>[]) List<String> details,
  }) = _AdviceItem;
}

/// Étape du pédiatre : consignes à partir de [fromMonths] mois révolus.
@freezed
abstract class AdviceStep with _$AdviceStep {
  const factory AdviceStep({
    required int fromMonths,
    required List<AdviceItem> items,
  }) = _AdviceStep;
}

/// Consignes de diversification remises par le pédiatre, regroupées à part
/// des repères OMS / France.
@freezed
abstract class PediatricianAdvice with _$PediatricianAdvice {
  const PediatricianAdvice._();

  const factory PediatricianAdvice({
    required String title,
    required String author,

    /// Portée des consignes (ex. sauf lait HPLV).
    required String scope,

    /// Étapes triées par âge strictement croissant.
    required List<AdviceStep> steps,

    /// Aliments à éviter, en une phrase.
    required String avoid,
  }) = _PediatricianAdvice;

  /// Dernière étape atteinte à [ageMonths] mois révolus, `null` avant la première.
  AdviceStep? currentStep(int ageMonths) =>
      steps.where((step) => step.fromMonths <= ageMonths).lastOrNull;
}
