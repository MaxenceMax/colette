import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/material.dart';

/// Heures de début et de fin d'un soin, côte à côte.
class EventTimeFields extends StatelessWidget {
  const EventTimeFields({
    super.key,
    required this.startAt,
    required this.endAt,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime startAt;
  final DateTime endAt;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      spacing: AppSpacing.sm.value,
      children: [
        Expanded(
          child: DateField(
            label: s.fieldStartAt,
            value: formatHourMinute(startAt),
            onTap: onPickStart,
          ),
        ),
        Expanded(
          child: DateField(
            label: s.fieldEndAt,
            value: formatHourMinute(endAt),
            onTap: onPickEnd,
          ),
        ),
      ],
    );
  }
}
