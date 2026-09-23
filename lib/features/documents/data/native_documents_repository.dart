import 'dart:developer' as developer;

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/data/dtos/document_entry_dto.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

const _reasons = {
  'noFolder': DocumentsReason.noFolder,
  'accessDenied': DocumentsReason.accessDenied,
  'cancelled': DocumentsReason.cancelled,
  'io': DocumentsReason.io,
};

/// Repository documents adossé au pont Swift : un [MethodChannel] pour les
/// appels, un [EventChannel] par dossier observé (nom fourni par Swift).
class NativeDocumentsRepository implements DocumentsRepository {
  const NativeDocumentsRepository(this._channel);

  /// Nom du canal de méthodes, partagé avec `DocumentsPlugin.swift`.
  static const channelName = 'colette/documents';

  final MethodChannel _channel;

  /// `PlatformException` → [DocumentsFailure] selon le code, sinon
  /// [UnknownFailure] avec un log.
  Failure _failure(Object error, StackTrace stackTrace) {
    if (error is PlatformException) {
      final reason = _reasons[error.code];
      if (reason != null) return DocumentsFailure(reason);
    }
    developer.log(
      'Documents natif',
      error: error,
      stackTrace: stackTrace,
      name: 'colette',
    );
    return UnknownFailure(error, stackTrace);
  }

  /// Comme `guard()`, avec le mapping des codes du canal en [DocumentsFailure].
  Future<Either<Failure, T>> _call<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } catch (e, stackTrace) {
      return left(_failure(e, stackTrace));
    }
  }

  DocumentRoot _root(Map<String, Object?> map) =>
      DocumentRoot(name: map['name'] as String);

  List<DocumentEntry> _entries(Object? raw) => [
    for (final item in (raw as List<Object?>?) ?? const [])
      DocumentEntryDto.fromMap(item! as Map<Object?, Object?>),
  ];

  @override
  Future<Either<Failure, DocumentRoot?>> rootFolder() => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>('rootFolder');
    return map == null ? null : _root(map);
  });

  @override
  Future<Either<Failure, DocumentRoot>> pickRootFolder() => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>(
      'pickRootFolder',
    );
    return _root(map!);
  });

  @override
  Future<Either<Failure, void>> forgetRootFolder() =>
      _call(() => _channel.invokeMethod<void>('forgetRootFolder'));

  @override
  Future<Either<Failure, List<DocumentEntry>>> list(String path) =>
      _call(() async {
        final raw = await _channel.invokeListMethod<Object?>('list', {
          'path': path,
        });
        return _entries(raw);
      });

  @override
  Stream<Either<Failure, List<DocumentEntry>>> watch(String path) async* {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>(
        'openFolderStream',
        {'path': path},
      );
      final channel = EventChannel(map!['channel'] as String);
      await for (final raw in channel.receiveBroadcastStream()) {
        yield right(_entries(raw));
      }
    } catch (e, stackTrace) {
      yield left(_failure(e, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> download(String path) =>
      _call(() => _channel.invokeMethod<void>('download', {'path': path}));

  @override
  Future<Either<Failure, void>> preview(String path) =>
      _call(() => _channel.invokeMethod<void>('preview', {'path': path}));

  @override
  Future<Either<Failure, void>> delete(String path) =>
      _call(() => _channel.invokeMethod<void>('delete', {'path': path}));

  @override
  Future<Either<Failure, void>> openInFiles(String path) =>
      _call(() => _channel.invokeMethod<void>('openInFiles', {'path': path}));

  @override
  Future<Either<Failure, String>> scan({
    required String folderPath,
    required String fileName,
  }) => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>('scan', {
      'path': folderPath,
      'fileName': fileName,
    });
    return map!['name'] as String;
  });

  @override
  Future<Either<Failure, String>> importFile({required String folderPath}) =>
      _call(() async {
        final map = await _channel.invokeMapMethod<String, Object?>(
          'importFile',
          {'path': folderPath},
        );
        return map!['name'] as String;
      });
}
