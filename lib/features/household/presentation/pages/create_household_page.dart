import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/household/presentation/providers/onboarding_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Saisie du prénom, de la date de naissance et du nom de l'appareil.
class CreateHouseholdPage extends ConsumerStatefulWidget {
  const CreateHouseholdPage({super.key});

  @override
  ConsumerState<CreateHouseholdPage> createState() =>
      _CreateHouseholdPageState();
}

class _CreateHouseholdPageState extends ConsumerState<CreateHouseholdPage> {
  final _nameController = TextEditingController();
  final _deviceController = TextEditingController();
  late DateTime _birthDate = ref.read(clockProvider).now().dateOnly;

  @override
  void dispose() {
    _nameController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _birthDate,
      mode: CupertinoDatePickerMode.date,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked != null) setState(() => _birthDate = picked.dateOnly);
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final label = _deviceController.text.trim().isEmpty
        ? s.fieldDeviceLabelHint
        : _deviceController.text;
    await ref
        .read(onboardingControllerProvider.notifier)
        .createHousehold(
          babyName: _nameController.text,
          birthDate: _birthDate,
          deviceLabel: label,
        );
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
      appBar: AppBar(title: Text(s.createHouseholdTitle)),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.lg.all,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: s.fieldBabyName),
              textCapitalization: .words,
            ),
            AppSpacing.md.verticalSpace,
            DateField(
              label: s.fieldBirthDate,
              value: DateFormat.yMMMMd('fr').format(_birthDate),
              onTap: _pickBirthDate,
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
              child: Text(s.actionCreate),
            ),
          ],
        ),
      ),
    );
  }
}
