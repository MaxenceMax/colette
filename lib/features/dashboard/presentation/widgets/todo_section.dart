import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/care_task_row.dart';
import 'package:colette/features/events/domain/use_cases/new_event_draft.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Liste des soins du jour : à faire en premier, faits ensuite, grisés.
class TodoSection extends ConsumerWidget {
  const TodoSection({super.key});

  Future<void> _quickAdd(
    BuildContext context,
    WidgetRef ref,
    CareType type,
  ) async {
    final s = S.of(context);
    final draft = newEventDraft(
      now: ref.read(clockProvider).now(),
      deviceId: ref.read(deviceIdProvider),
      id: ref.read(idGeneratorProvider).newId(),
      preChecked: type,
    );
    final saved = await ref
        .read(eventFormControllerProvider.notifier)
        .submit(draft);
    if (!context.mounted) return;
    if (saved == null) {
      if (ref.read(eventFormControllerProvider) case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.saved),
        action: SnackBarAction(
          label: s.actionUndo,
          onPressed: () {
            if (!context.mounted) return;
            ref.read(eventFormControllerProvider.notifier).delete(saved.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await de _quickAdd / annuler.
    ref.watch(eventFormControllerProvider);
    final s = S.of(context);
    final tasks = ref.watch(dailyCareTasksProvider);
    final pending = tasks.where((t) => !t.isDone).toList();
    final done = tasks.where((t) => t.isDone).toList();
    if (tasks.isEmpty) {
      return Text(
        s.todoAllDone,
        style: Theme.of(context).coletteTextStyles.body
            .copyWith(color: context.appColor(AppColors.textSecondary)),
      );
    }
    return Column(
      spacing: AppSpacing.sm.value,
      children: [
        for (final task in pending)
          CareTaskRow(
            task: task,
            onTap: () => _quickAdd(context, ref, task.type),
          ),
        for (final task in done) CareTaskRow(task: task, onTap: null),
      ],
    );
  }
}
