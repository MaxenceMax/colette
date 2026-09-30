// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_reminder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Date du dernier envoi réussi sur cet iPhone ; `null` si aucun.

@ProviderFor(LastPhotoSentAt)
final lastPhotoSentAtProvider = LastPhotoSentAtProvider._();

/// Date du dernier envoi réussi sur cet iPhone ; `null` si aucun.
final class LastPhotoSentAtProvider
    extends $AsyncNotifierProvider<LastPhotoSentAt, DateTime?> {
  /// Date du dernier envoi réussi sur cet iPhone ; `null` si aucun.
  LastPhotoSentAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'lastPhotoSentAtProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastPhotoSentAtHash();

  @$internal
  @override
  LastPhotoSentAt create() => LastPhotoSentAt();
}

String _$lastPhotoSentAtHash() => r'23ae107169a1e3faf47855acbe891157c2decb5a';

/// Date du dernier envoi réussi sur cet iPhone ; `null` si aucun.

abstract class _$LastPhotoSentAt extends $AsyncNotifier<DateTime?> {
  FutureOr<DateTime?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DateTime?>, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DateTime?>, DateTime?>,
              AsyncValue<DateTime?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Interrupteur du rappel photo quotidien (vrai par défaut).

@ProviderFor(PhotoReminderEnabled)
final photoReminderEnabledProvider = PhotoReminderEnabledProvider._();

/// Interrupteur du rappel photo quotidien (vrai par défaut).
final class PhotoReminderEnabledProvider
    extends $AsyncNotifierProvider<PhotoReminderEnabled, bool> {
  /// Interrupteur du rappel photo quotidien (vrai par défaut).
  PhotoReminderEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'photoReminderEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoReminderEnabledHash();

  @$internal
  @override
  PhotoReminderEnabled create() => PhotoReminderEnabled();
}

String _$photoReminderEnabledHash() =>
    r'f7da993ca5cdf533b7a5a0b032aa0ff1c3441011';

/// Interrupteur du rappel photo quotidien (vrai par défaut).

abstract class _$PhotoReminderEnabled extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Synchronisation du rappel photo.

@ProviderFor(photoReminderSync)
final photoReminderSyncProvider = PhotoReminderSyncProvider._();

/// Synchronisation du rappel photo.

final class PhotoReminderSyncProvider
    extends
        $FunctionalProvider<
          PhotoReminderSync,
          PhotoReminderSync,
          PhotoReminderSync
        >
    with $Provider<PhotoReminderSync> {
  /// Synchronisation du rappel photo.
  PhotoReminderSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoReminderSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoReminderSyncHash();

  @$internal
  @override
  $ProviderElement<PhotoReminderSync> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PhotoReminderSync create(Ref ref) {
    return photoReminderSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoReminderSync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoReminderSync>(value),
    );
  }
}

String _$photoReminderSyncHash() => r'e4f76c20c75442d657c67ded6db381e38dd5945c';
