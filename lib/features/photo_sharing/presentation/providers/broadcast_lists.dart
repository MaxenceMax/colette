import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'broadcast_lists.g.dart';

/// Listes de diffusion de cet iPhone. Chaque modification est enregistrée, à
/// la suite de la précédente ; en cas d'échec, l'état reste inchangé et la
/// failure est renvoyée.
@Riverpod(keepAlive: true, retry: noRetry)
class BroadcastLists extends _$BroadcastLists {
  /// File des écritures : chacune part de l'état laissé par la précédente.
  Future<void> _queue = Future.value();

  @override
  Future<List<BroadcastList>> build() async {
    final result = await ref.watch(photoSharingRepositoryProvider).loadLists();
    return result.fold((failure) => throw failure, (lists) => lists);
  }

  /// Crée une liste vide ; renvoie son identifiant.
  Future<Either<Failure, String>> create(String name) async {
    final id = ref.read(idGeneratorProvider).newId();
    final list = BroadcastList(id: id, name: name.trim(), recipients: const []);
    final saved = await _save((lists) => [...lists, list]);
    return saved.map((_) => id);
  }

  Future<Either<Failure, void>> rename(String id, String name) =>
      _update(id, (list) => list.copyWith(name: name.trim()));

  Future<Either<Failure, void>> delete(String id) => _save(
    (lists) => [
      for (final list in lists)
        if (list.id != id) list,
    ],
  );

  /// Sélecteur de contacts puis ajout ; sans effet si annulé.
  Future<Either<Failure, void>> addFromContacts(String id) async {
    final picked = await ref.read(photoSharingSystemProvider).pickContact();
    return switch (picked) {
      Left(:final value) => left(value),
      Right(value: null) => right(null),
      Right(value: final recipient?) => _update(
        id,
        (list) => list.withRecipient(recipient),
      ),
    };
  }

  Future<Either<Failure, void>> removeRecipient(String id, String phone) =>
      _update(id, (list) => list.withoutRecipient(phone));

  Future<Either<Failure, void>> _update(
    String id,
    BroadcastList Function(BroadcastList list) edit,
  ) => _save(
    (lists) => [for (final list in lists) list.id == id ? edit(list) : list],
  );

  Future<Either<Failure, void>> _save(
    List<BroadcastList> Function(List<BroadcastList> lists) edit,
  ) {
    final saved = _queue.then((_) => _saveNow(edit));
    // L'erreur est rendue à l'appelant par `saved` ; la file continue.
    _queue = saved.then<void>((_) {}, onError: (Object _) {});
    return saved;
  }

  Future<Either<Failure, void>> _saveNow(
    List<BroadcastList> Function(List<BroadcastList> lists) edit,
  ) async {
    final List<BroadcastList> current;
    try {
      current = await future;
    } on Failure {
      // Données illisibles : repartir d'une liste vide plutôt que bloquer.
      return _write(edit(const []));
    }
    return _write(edit(current));
  }

  Future<Either<Failure, void>> _write(List<BroadcastList> next) async {
    final result = await ref
        .read(photoSharingRepositoryProvider)
        .saveLists(next);
    if (result.isRight()) state = AsyncData(next);
    return result;
  }
}
