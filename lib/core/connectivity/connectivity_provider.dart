import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// `true` tant qu'au moins une interface réseau est disponible.
@riverpod
Stream<bool> isOnline(Ref ref) => Connectivity().onConnectivityChanged.map(
  (results) => results.isNotEmpty && !results.contains(ConnectivityResult.none),
);
