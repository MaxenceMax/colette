import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Prénom, date de naissance, chute du cordon.
class BabySection extends ConsumerWidget {
  const BabySection({super.key, required this.profile});

  final BabyProfile profile;

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.fieldBabyName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: .words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await ref
        .read(babySettingsControllerProvider.notifier)
        .saveProfile(profile.copyWith(name: name));
  }

  Future<void> _pickBirthDate(BuildContext context, WidgetRef ref) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: profile.birthDate,
      mode: CupertinoDatePickerMode.date,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked == null) return;
    await ref
        .read(babySettingsControllerProvider.notifier)
        .saveProfile(profile.copyWith(birthDate: picked.dateOnly));
  }

  Future<void> _pickCordFallenAt(BuildContext context, WidgetRef ref) async {
    final now = ref.read(clockProvider).now();
    final picked = await showColetteDateTimePicker(
      context,
      initial: profile.cordFallenAt ?? now.dateOnly,
      mode: CupertinoDatePickerMode.date,
      maximum: now,
    );
    if (picked == null) return;
    await ref
        .read(babySettingsControllerProvider.notifier)
        .setCordFallenAt(picked.dateOnly);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final dateFormat = DateFormat.yMMMMd('fr');
    return ColetteCardSurface(
      child: Column(
        spacing: AppSpacing.sm.value,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.fieldBabyName, style: styles.label),
            subtitle: Text(profile.name, style: styles.bodyLarge),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editName(context, ref),
          ),
          DateField(
            label: s.fieldBirthDate,
            value: dateFormat.format(profile.birthDate),
            onTap: () => _pickBirthDate(context, ref),
          ),
          Row(
            spacing: AppSpacing.sm.value,
            children: [
              Expanded(
                child: DateField(
                  label: s.settingsCordFallenAt,
                  value: switch (profile.cordFallenAt) {
                    null => s.settingsCordNotYet,
                    final date => dateFormat.format(date),
                  },
                  onTap: () => _pickCordFallenAt(context, ref),
                ),
              ),
              if (profile.cordFallenAt != null)
                IconButton(
                  onPressed: () => ref
                      .read(babySettingsControllerProvider.notifier)
                      .setCordFallenAt(null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
