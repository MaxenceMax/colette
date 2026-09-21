import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'firebase_providers.g.dart';

/// Instance Firestore ; surchargée par `FakeFirebaseFirestore` en test.
@riverpod
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

/// Instance Firebase Auth.
@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

/// Instance Firebase Messaging.
@riverpod
FirebaseMessaging firebaseMessaging(Ref ref) => FirebaseMessaging.instance;

/// Surchargé dans `main()` après `SharedPreferences.getInstance()`.
@riverpod
SharedPreferences sharedPreferences(Ref ref) => throw UnimplementedError(
  'sharedPreferencesProvider doit être surchargé dans main()',
);
