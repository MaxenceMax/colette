import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cible journalière : calcul OMS, ou stepper quand elle est ajustée.
/// Tient une copie locale optimiste, comme `CareSettingsSection`.
class FeedingTargetSection extends ConsumerStatefulWidget {
  const FeedingTargetSection({
    super.key,
    required this.profile,
    required this.omsTargetMl,
  });

  final BabyProfile profile;
  final int omsTargetMl;

  @override
  ConsumerState<FeedingTargetSection> createState() =>
      _FeedingTargetSectionState();
}

class _FeedingTargetSectionState extends ConsumerState<FeedingTargetSection> {
  late int? _target = widget.profile.careSettings.dailyTargetMl;

  @override
  void didUpdateWidget(covariant FeedingTargetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.profile.careSettings.dailyTargetMl;
    final writing = ref.read(babySettingsControllerProvider).isLoading;
    if (incoming != oldWidget.profile.careSettings.dailyTargetMl && !writing) {
      _target = incoming;
    }
  }

  void _write(int? target) {
    setState(() => _target = target);
    ref
        .read(babySettingsControllerProvider.notifier)
        .updateCareSettings(
          widget.profile,
          widget.profile.careSettings.copyWith(dailyTargetMl: target),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    final write = ref.watch(babySettingsControllerProvider);
    ref.listen(babySettingsControllerProvider, (_, next) {
      if (next is AsyncError) {
        setState(() => _target = widget.profile.careSettings.dailyTargetMl);
      }
    });
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final target = _target;
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.sm.value,
      children: [
        Text(
          s.feedingTargetTitle,
          style: styles.heading3.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
        Text(s.feedingTargetOms(widget.omsTargetMl), style: styles.body),
        if (write case AsyncError(:final error))
          Text(
            failureMessage(error, s),
            style: styles.small.copyWith(
              color: context.appColor(AppColors.error),
            ),
          ),
        if (target == null)
          FilledButton(
            onPressed: () => _write(
              widget.omsTargetMl.clamp(
                CareSettings.minDailyTargetMl,
                CareSettings.maxDailyTargetMl,
              ),
            ),
            child: Text(s.feedingTargetAdjust),
          )
        else ...[
          IntStepperRow(
            label: s.feedingTargetAdjusted,
            value: target,
            min: CareSettings.minDailyTargetMl,
            max: CareSettings.maxDailyTargetMl,
            step: CareSettings.dailyTargetStepMl,
            suffix: s.unitMl,
            onChanged: _write,
          ),
          TextButton(
            onPressed: () => _write(null),
            child: Text(s.feedingTargetReset),
          ),
        ],
      ],
    );
  }
}
