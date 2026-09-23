import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Intro du démarrage à froid : reprend l'écran de lancement natif, l'anime
/// puis s'efface pour révéler [child].
class SplashIntro extends StatefulWidget {
  const SplashIntro({required this.child, super.key});

  /// Clé de l'overlay, retiré de l'arbre à la fin de l'intro.
  static const overlayKey = ValueKey('splash-intro-overlay');

  final Widget child;

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends State<SplashIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == .completed) setState(() => _done = true);
    });
  bool _started = false;
  bool _firstFrameDeferred = true;
  bool _done = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    // Le launch screen natif reste affiché tant que l'image n'est pas décodée :
    // pas de frame vide entre les deux.
    WidgetsBinding.instance.deferFirstFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = _reduceMotion
        ? AppDuration.normal.value
        : AppDuration.splash.value;
    precacheImage(_image(context), context).whenComplete(_start);
  }

  void _start() {
    _allowFirstFrame();
    if (!mounted) return;
    _controller.forward();
  }

  void _allowFirstFrame() {
    if (!_firstFrameDeferred) return;
    _firstFrameDeferred = false;
    WidgetsBinding.instance.allowFirstFrame();
  }

  @override
  void dispose() {
    _allowFirstFrame();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (!_done)
        Positioned.fill(
          child: _SplashOverlay(
            key: SplashIntro.overlayKey,
            animation: _controller,
            reduceMotion: _reduceMotion,
            image: _image(context),
          ),
        ),
    ],
  );
}

/// Visuel de lancement (logo + wordmark), identique au launch screen natif.
AssetImage _image(BuildContext context) => AssetImage(
  Theme.of(context).brightness == .dark
      ? 'assets/brand/splash_dark.png'
      : 'assets/brand/splash.png',
);

class _SplashOverlay extends StatelessWidget {
  const _SplashOverlay({
    required this.animation,
    required this.reduceMotion,
    required this.image,
    super.key,
  });

  /// Bornes des étapes, en fraction de `AppDuration.splash` (1100 ms).
  static const _breathEnd = 600 / 1100;
  static const _slideStart = 400 / 1100;
  static const _slideEnd = 700 / 1100;
  static const _fadeStart = 700 / 1100;

  static final _breath = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.06), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1), weight: 1),
  ]).chain(CurveTween(curve: const Interval(0, _breathEnd)));

  final Animation<double> animation;
  final bool reduceMotion;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    final background = context.appColor(AppColors.pageBackground);
    final label = S.of(context).appTitle;
    final fadeStart = reduceMotion ? 0.0 : _fadeStart;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final fade = Interval(fadeStart, 1, curve: Curves.easeOut).transform(t);
        final slide = reduceMotion
            ? 0.0
            : const Interval(
                _slideStart,
                _slideEnd,
                curve: Curves.easeOut,
              ).transform(t);
        final scale = reduceMotion ? 1.0 : _breath.evaluate(animation);
        return AbsorbPointer(
          absorbing: t < fadeStart || t == 0,
          child: Opacity(
            opacity: 1 - fade,
            child: ColoredBox(
              color: background,
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, -AppSpacing.sm.value * slide),
                  child: Transform.scale(scale: scale, child: child),
                ),
              ),
            ),
          ),
        );
      },
      child: Semantics(
        label: label,
        image: true,
        child: ExcludeSemantics(child: Image(image: image)),
      ),
    );
  }
}
