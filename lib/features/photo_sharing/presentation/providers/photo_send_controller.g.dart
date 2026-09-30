// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_send_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Envoi des photos à chaque personne d'une liste, une feuille Messages par
/// personne ; `AsyncData(bilan)` à la fin, `null` avant tout envoi. La date
/// d'envoi (globale et de la liste) et le rappel sont enregistrés même si
/// l'écran a été fermé entre-temps.

@ProviderFor(PhotoSendController)
final photoSendControllerProvider = PhotoSendControllerProvider._();

/// Envoi des photos à chaque personne d'une liste, une feuille Messages par
/// personne ; `AsyncData(bilan)` à la fin, `null` avant tout envoi. La date
/// d'envoi (globale et de la liste) et le rappel sont enregistrés même si
/// l'écran a été fermé entre-temps.
final class PhotoSendControllerProvider
    extends $AsyncNotifierProvider<PhotoSendController, SendReport?> {
  /// Envoi des photos à chaque personne d'une liste, une feuille Messages par
  /// personne ; `AsyncData(bilan)` à la fin, `null` avant tout envoi. La date
  /// d'envoi (globale et de la liste) et le rappel sont enregistrés même si
  /// l'écran a été fermé entre-temps.
  PhotoSendControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoSendControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoSendControllerHash();

  @$internal
  @override
  PhotoSendController create() => PhotoSendController();
}

String _$photoSendControllerHash() =>
    r'bb1727bc9a117be97324219c07da418b4a1985f7';

/// Envoi des photos à chaque personne d'une liste, une feuille Messages par
/// personne ; `AsyncData(bilan)` à la fin, `null` avant tout envoi. La date
/// d'envoi (globale et de la liste) et le rappel sont enregistrés même si
/// l'écran a été fermé entre-temps.

abstract class _$PhotoSendController extends $AsyncNotifier<SendReport?> {
  FutureOr<SendReport?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SendReport?>, SendReport?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SendReport?>, SendReport?>,
              AsyncValue<SendReport?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
