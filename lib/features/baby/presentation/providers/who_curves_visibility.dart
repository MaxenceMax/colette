import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'who_curves_visibility.g.dart';

/// Courbes OMS affichées ou non sur la courbe de poids, mémorisé sur cet iPhone.
@Riverpod(keepAlive: true)
class WhoCurvesVisibility extends _$WhoCurvesVisibility {
  static const prefsKey = 'who_curves_visible';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(prefsKey) ?? false;

  Future<void> set(bool visible) async {
    state = visible;
    await ref.read(sharedPreferencesProvider).setBool(prefsKey, visible);
  }
}
