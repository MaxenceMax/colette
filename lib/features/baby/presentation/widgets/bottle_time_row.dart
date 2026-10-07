import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Ligne « 2e biberon … 10h30 » ; un appui ouvre la roue des heures.
class BottleTimeRow extends StatelessWidget {
  const BottleTimeRow({
    super.key,
    required this.index,
    required this.minutes,
    required this.onChanged,
  });

  /// Rang du biberon dans la journée, depuis 0.
  final int index;

  /// Horaire en minutes depuis minuit.
  final int minutes;

  final ValueChanged<int> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: DateTime(2000, 1, 1, 0, minutes),
      mode: .time,
      minuteInterval: CareSettings.bottleTimePickerStepMinutes,
    );
    if (picked == null) return;
    onChanged(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Row(
      children: [
        Expanded(
          child: Text(
            S.of(context).settingsBottleNth(index + 1),
            style: styles.body,
          ),
        ),
        TextButton(
          onPressed: () => _pick(context),
          child: Text(formatHourMinute(DateTime(2000, 1, 1, 0, minutes))),
        ),
      ],
    );
  }
}
