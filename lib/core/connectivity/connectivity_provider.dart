import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

bool _hasNetwork(List<ConnectivityResult> results) =>
    results.isNotEmpty && !results.contains(ConnectivityResult.none);

/// `true` tant qu'au moins une interface réseau est disponible.
/// Émet d'abord l'état courant, puis chaque changement.
@riverpod
Stream<bool> isOnline(Ref ref) async* {
  final connectivity = Connectivity();
  yield _hasNetwork(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasNetwork);
}
