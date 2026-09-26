import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Carrousel de cartes de RDV, haut comme la plus grande, avec points de
/// position.
class AppointmentCarousel extends StatefulWidget {
  const AppointmentCarousel({super.key, required this.pages});

  /// Cartes à faire défiler, dans l'ordre.
  final List<Widget> pages;

  @override
  State<AppointmentCarousel> createState() => _AppointmentCarouselState();
}

class _AppointmentCarouselState extends State<AppointmentCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(AppointmentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final last = widget.pages.length - 1;
    if (_index <= last) return;
    _index = last;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) _controller.jumpToPage(last);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (final page in widget.pages)
        Padding(padding: AppSpacing.xs.horizontal, child: page),
    ];
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm.value,
      children: [
        Stack(
          fit: .passthrough,
          children: [
            // Mesure : prend la taille de la plus grande page, sans la
            // peindre ni l'exposer aux taps et à la sémantique.
            IndexedStack(index: null, sizing: .passthrough, children: pages),
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => pages[i],
              ),
            ),
          ],
        ),
        _PageDots(index: _index, count: pages.length),
      ],
    );
  }
}

/// Points de position : actif en `primary`, les autres en `textSecondary`.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.of(context).healthAppointmentPosition(index + 1, count),
      child: Row(
        mainAxisAlignment: .center,
        spacing: AppSpacing.xs.value,
        children: [
          for (var i = 0; i < count; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                shape: .circle,
                color: context.appColor(
                  i == index ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              child: AppSize.nano.square,
            ),
        ],
      ),
    );
  }
}
