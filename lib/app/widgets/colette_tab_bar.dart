import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// Destination classique de la barre : icône et libellé.
class ColetteTabDestination {
  const ColetteTabDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Barre d'onglets maison : destinations classiques réparties autour d'un
/// bouton central rond surélevé (le menu principal).
class ColetteTabBar extends StatelessWidget {
  const ColetteTabBar({
    super.key,
    required this.destinations,
    required this.centerIcon,
    required this.centerLabel,
    required this.centerIndex,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Destinations classiques, dans l'ordre des index hors bouton central.
  final List<ColetteTabDestination> destinations;
  final IconData centerIcon;

  /// Libellé d'accessibilité du bouton central (jamais affiché).
  final String centerLabel;

  /// Index de branche du bouton central.
  final int centerIndex;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Débord du bouton central au-dessus de la barre.
  static final overflow = AppSpacing.lg.value;

  @override
  Widget build(BuildContext context) {
    final surface = context.appColor(AppColors.surface);
    return Stack(
      alignment: .topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(top: overflow),
          child: Material(
            color: surface,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: AppSize.xxl.value,
                child: Row(
                  children: [
                    for (final (i, d) in destinations.indexed) ...[
                      if (i == centerIndex) AppSize.huge.square,
                      Expanded(
                        child: _Destination(
                          destination: d,
                          selected: _branchIndex(i) == selectedIndex,
                          onTap: () => onSelected(_branchIndex(i)),
                        ),
                      ),
                    ],
                    if (centerIndex >= destinations.length) AppSize.huge.square,
                  ],
                ),
              ),
            ),
          ),
        ),
        _CenterButton(
          icon: centerIcon,
          label: centerLabel,
          selected: selectedIndex == centerIndex,
          onTap: () => onSelected(centerIndex),
        ),
      ],
    );
  }

  /// Index de branche d'une destination classique : le bouton central occupe
  /// [centerIndex], les suivantes sont décalées d'un cran.
  int _branchIndex(int destinationIndex) =>
      destinationIndex < centerIndex ? destinationIndex : destinationIndex + 1;
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ColetteTabDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.appColor(
      selected ? AppColors.primary : AppColors.textSecondary,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: .rectangle,
        child: Column(
          mainAxisAlignment: .center,
          spacing: AppSpacing.xxs.value,
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              color: color,
            ),
            ExcludeSemantics(
              child: Text(
                destination.label,
                style: Theme.of(context).coletteTextStyles.label
                    .copyWith(color: color),
                maxLines: 1,
                overflow: .ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Disque primaire surélevé, anneau `primaryContainer` quand il est actif.
class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          shape: .circle,
          boxShadow: AppElevation.high.boxShadow(
            context.appColor(AppColors.shadow),
          ),
        ),
        child: Material(
          color: context.appColor(AppColors.primary),
          shape: CircleBorder(
            side: selected
                ? BorderSide(
                    color: context.appColor(AppColors.primaryContainer),
                    width: AppSpacing.xs.value,
                  )
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: AppSize.xxxl.value,
              child: Icon(
                icon,
                color: context.appColor(AppColors.onPrimary),
                size: AppSize.md.value,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
