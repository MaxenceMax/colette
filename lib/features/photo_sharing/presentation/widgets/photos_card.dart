import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/photo_sharing/presentation/photo_labels.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Photos » sur Aujourd'hui : dernier envoi et accès aux listes.
class PhotosCard extends ConsumerWidget {
  const PhotosCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final now = ref.watch(currentMinuteProvider);
    final lastSentAt = ref.watch(lastPhotoSentAtProvider).value;
    return ColetteCardSurface(
      onTap: () => context.push(AppRoutes.todayPhotos),
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            color: context.appColor(AppColors.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(s.photosCardTitle, style: styles.bodyMedium),
                Text(
                  lastSentLabel(lastSentAt, now: now, s: s),
                  style: styles.small.copyWith(color: secondary),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: secondary),
        ],
      ),
    );
  }
}
