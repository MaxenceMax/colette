import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Préférences de notification de cet iPhone.
class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  static const minHour = 5;
  static const maxHour = 12;

  Future<void> _save(
    WidgetRef ref,
    DeviceInfo device, {
    bool enabling = false,
  }) async {
    await ref
        .read(notificationSettingsControllerProvider.notifier)
        .save(device);
    if (enabling) await ref.read(pushRegistrationProvider.notifier).register();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await de save.
    ref.watch(notificationSettingsControllerProvider);
    final s = S.of(context);
    final device = ref.watch(currentDeviceProvider).value;
    if (device == null) return const SizedBox.shrink();
    final body = Theme.of(context).coletteTextStyles.body;
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsNotifyOthersEvents, style: body),
            value: device.notifyOnOthersEvents,
            onChanged: (v) => _save(
              ref,
              device.copyWith(notifyOnOthersEvents: v),
              enabling: v,
            ),
          ),
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsNotifyBottle, style: body),
            value: device.notifyBottleReminder,
            onChanged: (v) => _save(
              ref,
              device.copyWith(notifyBottleReminder: v),
              enabling: v,
            ),
          ),
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsNotifyMorning, style: body),
            value: device.notifyMorningDigest,
            onChanged: (v) => _save(
              ref,
              device.copyWith(notifyMorningDigest: v),
              enabling: v,
            ),
          ),
          if (device.notifyMorningDigest)
            IntStepperRow(
              label: s.settingsMorningHour,
              value: device.morningDigestHour,
              min: minHour,
              max: maxHour,
              suffix: s.unitHour,
              onChanged: (v) =>
                  _save(ref, device.copyWith(morningDigestHour: v)),
            ),
        ],
      ),
    );
  }
}
