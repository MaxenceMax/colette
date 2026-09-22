import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Préférences de notification de cet iPhone.
/// Tient une copie locale optimiste : un échec d'enregistrement revient en arrière.
class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key, required this.device});

  final DeviceInfo device;

  static const minHour = 5;
  static const maxHour = 12;

  @override
  ConsumerState<NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
  late DeviceInfo _device = widget.device;

  @override
  void didUpdateWidget(covariant NotificationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final writing = ref.read(notificationSettingsControllerProvider).isLoading;
    if (widget.device != oldWidget.device && !writing) {
      _device = widget.device;
    }
  }

  Future<void> _update(DeviceInfo next, {bool enabling = false}) async {
    setState(() => _device = next);
    final ok = await ref
        .read(notificationSettingsControllerProvider.notifier)
        .save(next);
    if (!ok && mounted) setState(() => _device = widget.device);
    if (ok && enabling) ref.read(pushRegistrationProvider.notifier).register();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de save.
    ref.watch(notificationSettingsControllerProvider);
    final s = S.of(context);
    final body = Theme.of(context).coletteTextStyles.body;
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsNotifyOthersEvents, style: body),
            value: _device.notifyOnOthersEvents,
            onChanged: (v) =>
                _update(_device.copyWith(notifyOnOthersEvents: v), enabling: v),
          ),
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsNotifyBottle, style: body),
            value: _device.notifyBottleReminder,
            onChanged: (v) =>
                _update(_device.copyWith(notifyBottleReminder: v), enabling: v),
          ),
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsNotifyMorning, style: body),
            value: _device.notifyMorningDigest,
            onChanged: (v) =>
                _update(_device.copyWith(notifyMorningDigest: v), enabling: v),
          ),
          if (_device.notifyMorningDigest)
            IntStepperRow(
              label: s.settingsMorningHour,
              value: _device.morningDigestHour,
              min: NotificationsSection.minHour,
              max: NotificationsSection.maxHour,
              suffix: s.unitHour,
              onChanged: (v) => _update(_device.copyWith(morningDigestHour: v)),
            ),
        ],
      ),
    );
  }
}
