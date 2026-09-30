// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_sharing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stockage local du partage de photos.

@ProviderFor(photoSharingRepository)
final photoSharingRepositoryProvider = PhotoSharingRepositoryProvider._();

/// Stockage local du partage de photos.

final class PhotoSharingRepositoryProvider
    extends
        $FunctionalProvider<
          PhotoSharingRepository,
          PhotoSharingRepository,
          PhotoSharingRepository
        >
    with $Provider<PhotoSharingRepository> {
  /// Stockage local du partage de photos.
  PhotoSharingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoSharingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoSharingRepositoryHash();

  @$internal
  @override
  $ProviderElement<PhotoSharingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PhotoSharingRepository create(Ref ref) {
    return photoSharingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoSharingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoSharingRepository>(value),
    );
  }
}

String _$photoSharingRepositoryHash() =>
    r'30381fc121f68e7c84de74d83d52fedb05c9ea34';

/// Pont natif du partage de photos ; remplacé par un faux dans les tests.

@ProviderFor(photoSharingSystem)
final photoSharingSystemProvider = PhotoSharingSystemProvider._();

/// Pont natif du partage de photos ; remplacé par un faux dans les tests.

final class PhotoSharingSystemProvider
    extends
        $FunctionalProvider<
          PhotoSharingSystem,
          PhotoSharingSystem,
          PhotoSharingSystem
        >
    with $Provider<PhotoSharingSystem> {
  /// Pont natif du partage de photos ; remplacé par un faux dans les tests.
  PhotoSharingSystemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoSharingSystemProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoSharingSystemHash();

  @$internal
  @override
  $ProviderElement<PhotoSharingSystem> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PhotoSharingSystem create(Ref ref) {
    return photoSharingSystem(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoSharingSystem value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoSharingSystem>(value),
    );
  }
}

String _$photoSharingSystemHash() =>
    r'5ea850d9b943bc6b6b8c182a698cb3fd67ea5218';
