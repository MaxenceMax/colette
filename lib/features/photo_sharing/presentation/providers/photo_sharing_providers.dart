import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/photo_sharing/data/native_photo_sharing_system.dart';
import 'package:colette/features/photo_sharing/data/repositories/prefs_photo_sharing_repository.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_repository.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_system.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_sharing_providers.g.dart';

/// Stockage local du partage de photos.
@Riverpod(keepAlive: true)
PhotoSharingRepository photoSharingRepository(Ref ref) =>
    PrefsPhotoSharingRepository(ref.watch(sharedPreferencesProvider));

/// Pont natif du partage de photos ; remplacé par un faux dans les tests.
@Riverpod(keepAlive: true)
PhotoSharingSystem photoSharingSystem(Ref ref) => NativePhotoSharingSystem(
  const MethodChannel(NativePhotoSharingSystem.channelName),
);
