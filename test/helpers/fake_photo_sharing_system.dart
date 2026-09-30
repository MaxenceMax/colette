import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_system.dart';
import 'package:fpdart/fpdart.dart';

/// Pont natif simulé : réponses réglables, appels enregistrés.
class FakePhotoSharingSystem implements PhotoSharingSystem {
  FakePhotoSharingSystem({this.pendingRoute});

  Recipient? contact;
  Failure? contactFailure;
  List<String> photos = const [];
  Failure? photosFailure;
  SendReport report = const SendReport(sent: 0, cancelled: 0, failed: 0);
  Failure? sendFailure;
  String? pendingRoute;

  /// Retient `sendMessages` jusqu'à sa complétion.
  Completer<void>? sendGate;

  /// Levée par `syncReminders` si non nulle.
  Object? syncError;

  final signals = StreamController<void>.broadcast();
  final sendCalls =
      <({List<String> phones, List<String> photoPaths, String body})>[];
  final discarded = <String>[];
  final syncedDates = <List<DateTime>>[];
  final syncedBodies = <String>[];
  String? lastTitle;
  String? lastBody;

  @override
  Future<Either<Failure, Recipient?>> pickContact() async =>
      contactFailure == null ? right(contact) : left(contactFailure!);

  @override
  Future<Either<Failure, List<String>>> takePhoto() async =>
      photosFailure == null ? right(photos) : left(photosFailure!);

  @override
  Future<Either<Failure, List<String>>> pickPhotos() async =>
      photosFailure == null ? right(photos) : left(photosFailure!);

  @override
  Future<Either<Failure, SendReport>> sendMessages({
    required List<String> phones,
    required List<String> photoPaths,
    required String body,
  }) async {
    sendCalls.add((phones: phones, photoPaths: photoPaths, body: body));
    await sendGate?.future;
    return sendFailure == null ? right(report) : left(sendFailure!);
  }

  @override
  Future<void> discardPhotos(List<String> photoPaths) async =>
      discarded.addAll(photoPaths);

  @override
  Future<void> syncReminders({
    required List<DateTime> dates,
    required String title,
    required String body,
  }) async {
    if (syncError case final error?) throw error;
    syncedDates.add(dates);
    syncedBodies.add(body);
    lastTitle = title;
    lastBody = body;
  }

  @override
  Future<String?> takePendingRoute() async {
    final route = pendingRoute;
    pendingRoute = null;
    return route;
  }

  @override
  Stream<void> get pendingRouteSignals => signals.stream;
}
