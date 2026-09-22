import 'package:colette/core/firebase/anonymous_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuth auth;

  setUp(() => auth = MockFirebaseAuth());

  test('ne fait rien si une session existe déjà', () async {
    when(() => auth.currentUser).thenReturn(MockUser());
    await ensureAnonymousSession(auth);
    verifyNever(() => auth.signInAnonymously());
  });

  test('ouvre une session anonyme si aucune n\'existe', () async {
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.signInAnonymously())
        .thenAnswer((_) async => MockUserCredential());
    await ensureAnonymousSession(auth);
    verify(() => auth.signInAnonymously()).called(1);
  });

  test('avale une FirebaseAuthException sans la propager', () async {
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.signInAnonymously())
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await expectLater(ensureAnonymousSession(auth), completes);
  });

  test('avale toute autre exception du plugin sans la propager', () async {
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.signInAnonymously()).thenThrow(Exception('boom'));
    await expectLater(ensureAnonymousSession(auth), completes);
  });
}
