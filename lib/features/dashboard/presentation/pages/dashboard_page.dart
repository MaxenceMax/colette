import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/dashboard/presentation/providers/bottle_form_request.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:colette/features/dashboard/presentation/widgets/day_counters_row.dart';
import 'package:colette/features/dashboard/presentation/widgets/next_bottle_card.dart';
import 'package:colette/features/dashboard/presentation/widgets/todo_section.dart';
import 'package:colette/features/dashboard/presentation/widgets/weight_card.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_alert_card.dart';
import 'package:colette/features/documents/presentation/widgets/documents_card.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Aujourd'hui : âge, prochain biberon, reste à faire, compteurs,
/// poids, documents.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(bottleFormRequestProvider, fireImmediately: true, (
      _,
      requested,
    ) {
      if (!requested) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(bottleFormRequestProvider.notifier).consume();
        final plan = ref.read(feedingPlanProvider);
        showEventFormSheet(context, suggestedBottleMl: plan?.suggestedMl);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.md.all,
          children: [
            const DashboardHeader(),
            AppSpacing.md.verticalSpace,
            const DiaperStockAlertCard(),
            const NextBottleCard(),
            SectionHeader(title: s.todoTitle),
            const TodoSection(),
            AppSpacing.lg.verticalSpace,
            const DayCountersRow(),
            AppSpacing.lg.verticalSpace,
            const WeightCard(),
            AppSpacing.md.verticalSpace,
            const DocumentsCard(),
            AppSpacing.xl.verticalSpace,
          ],
        ),
      ),
    );
  }
}
