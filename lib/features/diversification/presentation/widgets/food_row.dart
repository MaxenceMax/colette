import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/presentation/widgets/food_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Ligne du catalogue : nom et statut ; ouvre la fiche de l'aliment.
class FoodRow extends StatelessWidget {
  const FoodRow({super.key, required this.food, required this.status});

  final Food food;
  final FoodStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return InkWell(
      onTap: () => context.push(AppRoutes.plateFood(food.id)),
      child: Padding(
        padding: AppSpacing.sm.vertical,
        child: Row(
          spacing: AppSpacing.sm.value,
          children: [
            Expanded(
              child: Text(
                food.name,
                style: Theme.of(context).coletteTextStyles.body,
              ),
            ),
            if (status != null)
              Flexible(child: FoodStatusBadge(status: status)),
          ],
        ),
      ),
    );
  }
}
