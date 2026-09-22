// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Source de push utilisée par l'app ; Firebase Cloud Messaging en production.

@ProviderFor(pushTokenSource)
final pushTokenSourceProvider = PushTokenSourceProvider._();

/// Source de push utilisée par l'app ; Firebase Cloud Messaging en production.

final class PushTokenSourceProvider
    extends
        $FunctionalProvider<PushTokenSource, PushTokenSource, PushTokenSource>
    with $Provider<PushTokenSource> {
  /// Source de push utilisée par l'app ; Firebase Cloud Messaging en production.
  PushTokenSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushTokenSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushTokenSourceHash();

  @$internal
  @override
  $ProviderElement<PushTokenSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushTokenSource create(Ref ref) {
    return pushTokenSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushTokenSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushTokenSource>(value),
    );
  }
}

String _$pushTokenSourceHash() => r'15baf66c10ffcbe0b10cfbc86acb9aa91921b985';

/// Enregistre le token FCM de cet iPhone dans le foyer et suit ses renouvellements.

@ProviderFor(PushRegistration)
final pushRegistrationProvider = PushRegistrationProvider._();

/// Enregistre le token FCM de cet iPhone dans le foyer et suit ses renouvellements.
final class PushRegistrationProvider
    extends $AsyncNotifierProvider<PushRegistration, void> {
  /// Enregistre le token FCM de cet iPhone dans le foyer et suit ses renouvellements.
  PushRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrationHash();

  @$internal
  @override
  PushRegistration create() => PushRegistration();
}

String _$pushRegistrationHash() => r'ef2102c01eda7544fed0fd340e24e22948bf4ef2';

/// Enregistre le token FCM de cet iPhone dans le foyer et suit ses renouvellements.

abstract class _$PushRegistration extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Enregistre les préférences de notification de cet iPhone.

@ProviderFor(NotificationSettingsController)
final notificationSettingsControllerProvider =
    NotificationSettingsControllerProvider._();

/// Enregistre les préférences de notification de cet iPhone.
final class NotificationSettingsControllerProvider
    extends $AsyncNotifierProvider<NotificationSettingsController, void> {
  /// Enregistre les préférences de notification de cet iPhone.
  NotificationSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSettingsControllerHash();

  @$internal
  @override
  NotificationSettingsController create() => NotificationSettingsController();
}

String _$notificationSettingsControllerHash() =>
    r'e579c058898adf0260aea5afa64494fca096f189';

/// Enregistre les préférences de notification de cet iPhone.

abstract class _$NotificationSettingsController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
