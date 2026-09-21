import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'firebase_providers.g.dart';

/// Instance Firestore ; surchargée par `FakeFirebaseFirestore` en test.
/// Singleton applicatif : `keepAlive` pour pouvoir être consommé par des providers `keepAlive`.
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

/// Instance Firebase Auth.
/// Singleton applicatif : `keepAlive` pour pouvoir être consommé par des providers `keepAlive`.
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

/// Instance Firebase Messaging.
/// Singleton applicatif : `keepAlive` pour pouvoir être consommé par des providers `keepAlive`.
@Riverpod(keepAlive: true)
FirebaseMessaging firebaseMessaging(Ref ref) => FirebaseMessaging.instance;

/// Surchargé dans `main()` après `SharedPreferences.getInstance()`.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) => throw UnimplementedError(
  'sharedPreferencesProvider doit être surchargé dans main()',
);
