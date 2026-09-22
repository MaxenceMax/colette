import 'package:colette/core/result/failure.dart';

/// Politique `retry` Riverpod qui désactive la relance automatique :
/// une [Failure] relancée par un `build` doit remonter tout de suite en `AsyncError`.
Duration? noRetry(int retryCount, Object error) => null;
