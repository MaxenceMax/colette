import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/household/domain/household_code_generator.dart';
import 'package:colette/features/household/presentation/providers/onboarding_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saisie du code foyer et du nom de l'appareil.
class JoinHouseholdPage extends ConsumerStatefulWidget {
  const JoinHouseholdPage({super.key});

  @override
  ConsumerState<JoinHouseholdPage> createState() => _JoinHouseholdPageState();
}

class _JoinHouseholdPageState extends ConsumerState<JoinHouseholdPage> {
  final _codeController = TextEditingController();
  final _deviceController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(onboardingControllerProvider).isLoading) return;
    final s = S.of(context);
    final label = _deviceController.text.trim().isEmpty
        ? s.deviceLabelDefault
        : _deviceController.text;
    await ref
        .read(onboardingControllerProvider.notifier)
        .joinHousehold(code: _codeController.text, deviceLabel: label);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    ref.listen(onboardingControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final isLoading = ref.watch(onboardingControllerProvider) is AsyncLoading;
    return Scaffold(
      appBar: AppBar(title: Text(s.joinHouseholdTitle)),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.lg.all,
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: s.fieldHouseholdCode),
              textCapitalization: .characters,
              maxLength: HouseholdCodeGenerator.length,
              autocorrect: false,
            ),
            AppSpacing.md.verticalSpace,
            TextField(
              controller: _deviceController,
              decoration: InputDecoration(
                labelText: s.fieldDeviceLabel,
                hintText: s.fieldDeviceLabelHint,
              ),
            ),
            AppSpacing.xl.verticalSpace,
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: Text(s.actionJoin),
            ),
          ],
        ),
      ),
    );
  }
}
