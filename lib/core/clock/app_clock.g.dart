// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_clock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Horloge de l'app ; surchargée par une [FixedClock] dans les tests.

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// Horloge de l'app ; surchargée par une [FixedClock] dans les tests.

final class ClockProvider
    extends $FunctionalProvider<AppClock, AppClock, AppClock>
    with $Provider<AppClock> {
  /// Horloge de l'app ; surchargée par une [FixedClock] dans les tests.
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<AppClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppClock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppClock>(value),
    );
  }
}

String _$clockHash() => r'2a9fdfbba27d0ebfdeeaeaec34af6d85f59a89d0';
