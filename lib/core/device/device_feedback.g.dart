// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_feedback.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Retours de l'appareil ; remplacé par un faux dans les tests.

@ProviderFor(deviceFeedback)
final deviceFeedbackProvider = DeviceFeedbackProvider._();

/// Retours de l'appareil ; remplacé par un faux dans les tests.

final class DeviceFeedbackProvider
    extends $FunctionalProvider<DeviceFeedback, DeviceFeedback, DeviceFeedback>
    with $Provider<DeviceFeedback> {
  /// Retours de l'appareil ; remplacé par un faux dans les tests.
  DeviceFeedbackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceFeedbackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceFeedbackHash();

  @$internal
  @override
  $ProviderElement<DeviceFeedback> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceFeedback create(Ref ref) {
    return deviceFeedback(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceFeedback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceFeedback>(value),
    );
  }
}

String _$deviceFeedbackHash() => r'219296c37f7300a9fd6f85d4676444d02836c87d';
