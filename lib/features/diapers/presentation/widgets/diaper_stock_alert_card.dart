import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Plus que N couches », visible uniquement sous le seuil d'alerte.
/// Tap : ouvre l'onglet Réglages.
class DiaperStockAlertCard extends ConsumerWidget {
  const DiaperStockAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Uniquement sur des données chargées : ni pendant le chargement, ni en erreur.
    if (ref.watch(diaperStockStatusProvider)
        case AsyncData(value: final status?) when status.isLow) {
      return _AlertCard(remaining: status.remaining);
    }
    return const SizedBox.shrink();
  }
}

/// Corps de la carte, sur fond `warning` ; le texte en `onPrimary` (paire validée par le test de contraste).
class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final color = context.appColor(AppColors.onPrimary);
    // Marge portée par la carte : un espaceur dans la ListView laisserait un trou quand la carte est masquée.
    return Padding(
      padding: AppSpacing.md.bottom,
      child: ColetteCardSurface(
        backgroundColor: AppColors.warning,
        borderColor: AppColors.warning,
        onTap: () => context.go(AppRoutes.settings),
        child: Row(
          children: [
            Icon(Icons.baby_changing_station, color: color),
            AppSpacing.sm.horizontalSpace,
            Expanded(
              child: Text(
                S.of(context).diapersAlertLow(remaining),
                style: Theme.of(context).coletteTextStyles.bodyMedium
                    .copyWith(color: color),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
