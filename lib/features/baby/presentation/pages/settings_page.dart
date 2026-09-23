import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/baby_section.dart';
import 'package:colette/features/baby/presentation/widgets/care_settings_section.dart';
import 'package:colette/features/baby/presentation/widgets/measurements_section.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_controller.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_section.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/household/presentation/widgets/household_section.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:colette/features/notifications/presentation/widgets/notifications_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:colette/shared/ui/widgets/theme_mode_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Réglages : bébé, mesures, soins attendus, notifications, apparence, foyer.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    ref.listen(babySettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    ref.listen(notificationSettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    ref.listen(diaperStockControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final profile = ref.watch(babyProfileProvider).value;
    final code = ref.watch(currentHouseholdCodeProvider);
    final device = ref.watch(currentDeviceProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: [
          if (profile != null) ...[
            SectionHeader(title: s.settingsBabySection),
            BabySection(profile: profile),
            SectionHeader(title: s.settingsMeasurementsSection),
            const MeasurementsSection(),
            SectionHeader(title: s.settingsCareSection),
            CareSettingsSection(profile: profile),
          ] else
            const Padding(
              padding: EdgeInsets.zero,
              child: Center(child: CircularProgressIndicator()),
            ),
          SectionHeader(title: s.settingsDiapersSection),
          const DiaperStockSection(),
          if (device != null) ...[
            SectionHeader(title: s.settingsNotificationsSection),
            NotificationsSection(device: device),
          ],
          SectionHeader(title: s.settingsAppearanceSection),
          const ThemeModeSection(),
          if (code != null) ...[
            SectionHeader(title: s.settingsHouseholdSection),
            HouseholdSection(code: code),
          ],
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}
