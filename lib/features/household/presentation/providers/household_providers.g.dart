// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(householdLocalStore)
final householdLocalStoreProvider = HouseholdLocalStoreProvider._();

final class HouseholdLocalStoreProvider
    extends
        $FunctionalProvider<
          HouseholdLocalStore,
          HouseholdLocalStore,
          HouseholdLocalStore
        >
    with $Provider<HouseholdLocalStore> {
  HouseholdLocalStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdLocalStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdLocalStoreHash();

  @$internal
  @override
  $ProviderElement<HouseholdLocalStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdLocalStore create(Ref ref) {
    return householdLocalStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdLocalStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdLocalStore>(value),
    );
  }
}

String _$householdLocalStoreHash() =>
    r'08c657f31c17d2f5b7e337b1657dddbcda0ff1f8';

@ProviderFor(householdRepository)
final householdRepositoryProvider = HouseholdRepositoryProvider._();

final class HouseholdRepositoryProvider
    extends
        $FunctionalProvider<
          HouseholdRepository,
          HouseholdRepository,
          HouseholdRepository
        >
    with $Provider<HouseholdRepository> {
  HouseholdRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdRepositoryHash();

  @$internal
  @override
  $ProviderElement<HouseholdRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdRepository create(Ref ref) {
    return householdRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdRepository>(value),
    );
  }
}

String _$householdRepositoryHash() =>
    r'1711b63e94f82c7c25221dcc771f86c6f43af71e';

@ProviderFor(deviceRepository)
final deviceRepositoryProvider = DeviceRepositoryProvider._();

final class DeviceRepositoryProvider
    extends
        $FunctionalProvider<
          DeviceRepository,
          DeviceRepository,
          DeviceRepository
        >
    with $Provider<DeviceRepository> {
  DeviceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceRepositoryHash();

  @$internal
  @override
  $ProviderElement<DeviceRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceRepository create(Ref ref) {
    return deviceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceRepository>(value),
    );
  }
}

String _$deviceRepositoryHash() => r'f1ddc12099f8d06fd6bfb56979a42fec603d6684';

@ProviderFor(householdCodeGenerator)
final householdCodeGeneratorProvider = HouseholdCodeGeneratorProvider._();

final class HouseholdCodeGeneratorProvider
    extends
        $FunctionalProvider<
          HouseholdCodeGenerator,
          HouseholdCodeGenerator,
          HouseholdCodeGenerator
        >
    with $Provider<HouseholdCodeGenerator> {
  HouseholdCodeGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdCodeGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdCodeGeneratorHash();

  @$internal
  @override
  $ProviderElement<HouseholdCodeGenerator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdCodeGenerator create(Ref ref) {
    return householdCodeGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdCodeGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdCodeGenerator>(value),
    );
  }
}

String _$householdCodeGeneratorHash() =>
    r'8820346be636507344725f6f91ff70641cb8dc3f';

/// Code du foyer courant ; `null` tant que l'onboarding n'est pas terminé.

@ProviderFor(CurrentHouseholdCode)
final currentHouseholdCodeProvider = CurrentHouseholdCodeProvider._();

/// Code du foyer courant ; `null` tant que l'onboarding n'est pas terminé.
final class CurrentHouseholdCodeProvider
    extends $NotifierProvider<CurrentHouseholdCode, String?> {
  /// Code du foyer courant ; `null` tant que l'onboarding n'est pas terminé.
  CurrentHouseholdCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentHouseholdCodeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentHouseholdCodeHash();

  @$internal
  @override
  CurrentHouseholdCode create() => CurrentHouseholdCode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentHouseholdCodeHash() =>
    r'27e5674abb3725f91fefd296bb46937b9acdcd18';

/// Code du foyer courant ; `null` tant que l'onboarding n'est pas terminé.

abstract class _$CurrentHouseholdCode extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Identifiant stable de cet iPhone.

@ProviderFor(deviceId)
final deviceIdProvider = DeviceIdProvider._();

/// Identifiant stable de cet iPhone.

final class DeviceIdProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Identifiant stable de cet iPhone.
  DeviceIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return deviceId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$deviceIdHash() => r'f0edd77a3dea2d411aabc19fcdc419853b94e59a';

/// Document de cet iPhone dans le foyer courant.

@ProviderFor(currentDevice)
final currentDeviceProvider = CurrentDeviceProvider._();

/// Document de cet iPhone dans le foyer courant.

final class CurrentDeviceProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeviceInfo?>,
          DeviceInfo?,
          Stream<DeviceInfo?>
        >
    with $FutureModifier<DeviceInfo?>, $StreamProvider<DeviceInfo?> {
  /// Document de cet iPhone dans le foyer courant.
  CurrentDeviceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDeviceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDeviceHash();

  @$internal
  @override
  $StreamProviderElement<DeviceInfo?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DeviceInfo?> create(Ref ref) {
    return currentDevice(ref);
  }
}

String _$currentDeviceHash() => r'524f034f9a9eac79fa1474a35b58668b6de666aa';
