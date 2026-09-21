// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Émet chaque minute ; surchargé par `Stream.empty()` dans les tests.

@ProviderFor(minuteTicker)
final minuteTickerProvider = MinuteTickerProvider._();

/// Émet chaque minute ; surchargé par `Stream.empty()` dans les tests.

final class MinuteTickerProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// Émet chaque minute ; surchargé par `Stream.empty()` dans les tests.
  MinuteTickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minuteTickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minuteTickerHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return minuteTicker(ref);
  }
}

String _$minuteTickerHash() => r'dc9c9038005ad9721e70337ecf3c478ca4e63c0c';

/// Heure courante, rafraîchie chaque minute.

@ProviderFor(currentMinute)
final currentMinuteProvider = CurrentMinuteProvider._();

/// Heure courante, rafraîchie chaque minute.

final class CurrentMinuteProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// Heure courante, rafraîchie chaque minute.
  CurrentMinuteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMinuteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMinuteHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return currentMinute(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$currentMinuteHash() => r'0354631de42e0129b19f58dbe63a447610e075c2';

/// Jour civil courant ; ne notifie ses dépendants qu'au changement de jour.

@ProviderFor(today)
final todayProvider = TodayProvider._();

/// Jour civil courant ; ne notifie ses dépendants qu'au changement de jour.

final class TodayProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// Jour civil courant ; ne notifie ses dépendants qu'au changement de jour.
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return today(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$todayHash() => r'910d7d7819309668f5d8f86bc837a9a098c1ee4f';
