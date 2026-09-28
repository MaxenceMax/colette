# Live Activity du minuteur de biberon — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** le minuteur de biberon vit hors de l'app (Live Activity, notifications locales) et reprend après une app tuée.

**Architecture:** côté Dart, une session (minuteur + brouillon) persistée dans `shared_preferences`, un pont natif `colette/bottle-timer` (`sync` / `clear`) piloté par `bottleTimerEffectsProvider`, un gate de reprise au démarrage. Côté iOS, un canal dans `AppDelegate` qui gère ActivityKit et `UNUserNotificationCenter`, et une Widget Extension SwiftUI `BottleTimerWidget`.

**Tech Stack:** Flutter, Riverpod 3 codegen, freezed, fpdart, shared_preferences ; Swift, ActivityKit, WidgetKit, UserNotifications ; gem `xcodeproj` pour créer la target.

Spec : `docs/superpowers/specs/2026-09-28-bottle-live-activity-design.md`.

Commandes communes (depuis la racine du worktree) :
- codegen : `dart run build_runner build -d`
- l10n : `flutter gen-l10n`
- vérification : `dart format lib test && dart analyze && flutter test`

---

## Fichiers

Créés :
- `lib/features/events/domain/entities/bottle_timer_session.dart` : entité + expiration.
- `lib/features/events/domain/repositories/bottle_timer_session_repository.dart` : interface.
- `lib/features/events/domain/use_cases/resumable_bottle_timer_session.dart` : session à reprendre.
- `lib/features/events/data/dtos/bottle_timer_session_dto.dart` : JSON.
- `lib/features/events/data/repositories/prefs_bottle_timer_session_repository.dart`.
- `lib/features/events/presentation/providers/bottle_timer_session_providers.dart` : repository + demande de reprise.
- `lib/core/device/bottle_timer_system.dart` : pont natif.
- `lib/features/events/presentation/widgets/bottle_timer_stop_dialog.dart` : dialogue extrait de la feuille (limite 300 lignes).
- `lib/app/bottle_timer_resume_gate.dart`.
- `test/helpers/in_memory_bottle_timer_session_repository.dart`, `test/helpers/fake_bottle_timer_system.dart`.
- Tests : `test/features/events/domain/entities/bottle_timer_session_test.dart`, `test/features/events/domain/use_cases/resumable_bottle_timer_session_test.dart`, `test/features/events/data/prefs_bottle_timer_session_repository_test.dart`, `test/app/bottle_timer_resume_gate_test.dart`.
- iOS : `ios/Runner/BottleTimer/BottleTimerAttributes.swift`, `ios/Runner/BottleTimer/BottleTimerChannel.swift`, `ios/BottleTimerWidget/…`, `ios/scripts/add_bottle_timer_widget.rb`.

Modifiés :
- `lib/features/events/presentation/providers/bottle_timer_controller.dart` : `restore`, effets.
- `lib/features/events/presentation/widgets/event_form_sheet.dart` : `restored`, persistance.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` : ouverture sur reprise.
- `lib/app/colette_app.dart` : gate.
- `test/helpers/pump_app.dart`, `test/helpers/colette_app_overrides.dart` : fakes par défaut.
- `test/features/events/presentation/bottle_timer_controller_test.dart`, `test/features/events/presentation/event_form_sheet_timer_test.dart`.
- `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`.

---

### Task 1 : entité `BottleTimerSession`, interface et reprise

**Files:**
- Create: `lib/features/events/domain/entities/bottle_timer_session.dart`
- Create: `lib/features/events/domain/repositories/bottle_timer_session_repository.dart`
- Create: `lib/features/events/domain/use_cases/resumable_bottle_timer_session.dart`
- Create: `test/helpers/in_memory_bottle_timer_session_repository.dart`
- Test: `test/features/events/domain/entities/bottle_timer_session_test.dart`
- Test: `test/features/events/domain/use_cases/resumable_bottle_timer_session_test.dart`

- [ ] **Step 1 : tests rouges**

`test/helpers/in_memory_bottle_timer_session_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/repositories/bottle_timer_session_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Session gardée en mémoire ; [failLoad] simule une session illisible.
class InMemoryBottleTimerSessionRepository
    implements BottleTimerSessionRepository {
  InMemoryBottleTimerSessionRepository({this.session, this.failLoad = false});

  BottleTimerSession? session;
  bool failLoad;
  int clears = 0;

  @override
  Future<Either<Failure, void>> save(BottleTimerSession session) async {
    this.session = session;
    return right(null);
  }

  @override
  Future<Either<Failure, BottleTimerSession?>> load() async => failLoad
      ? left(UnknownFailure(StateError('illisible'), StackTrace.empty))
      : right(session);

  @override
  Future<Either<Failure, void>> clear() async {
    clears++;
    session = null;
    failLoad = false;
    return right(null);
  }
}
```

`test/features/events/domain/entities/bottle_timer_session_test.dart` :

```dart
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/care_event_factory.dart';

void main() {
  final start = DateTime(2026, 9, 28, 2);
  final session = BottleTimerSession(
    run: BottleTimerRun.startingAt(start),
    draft: makeEvent(startAt: start),
    editing: false,
  );

  test('pas expirée à 12 h pile', () {
    expect(session.isExpiredAt(start.add(const Duration(hours: 12))), isFalse);
  });

  test('expirée au-delà de 12 h', () {
    expect(
      session.isExpiredAt(start.add(const Duration(hours: 12, minutes: 1))),
      isTrue,
    );
  });
}
```

`test/features/events/domain/use_cases/resumable_bottle_timer_session_test.dart` :

```dart
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/use_cases/resumable_bottle_timer_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/care_event_factory.dart';
import '../../../../helpers/in_memory_bottle_timer_session_repository.dart';

void main() {
  final start = DateTime(2026, 9, 28, 2);
  final session = BottleTimerSession(
    run: BottleTimerRun.startingAt(start),
    draft: makeEvent(startAt: start),
    editing: false,
  );

  test('aucune session : null, rien effacé', () async {
    final repo = InMemoryBottleTimerSessionRepository();
    final result = await resumableBottleTimerSession(
      repository: repo,
      now: start,
    );
    expect(result, isNull);
    expect(repo.clears, 0);
  });

  test('session récente : renvoyée et conservée', () async {
    final repo = InMemoryBottleTimerSessionRepository(session: session);
    final result = await resumableBottleTimerSession(
      repository: repo,
      now: start.add(const Duration(hours: 1)),
    );
    expect(result, session);
    expect(repo.session, session);
  });

  test('session expirée : null et effacée', () async {
    final repo = InMemoryBottleTimerSessionRepository(session: session);
    final result = await resumableBottleTimerSession(
      repository: repo,
      now: start.add(const Duration(hours: 13)),
    );
    expect(result, isNull);
    expect(repo.session, isNull);
  });

  test('session illisible : null et effacée', () async {
    final repo = InMemoryBottleTimerSessionRepository(failLoad: true);
    final result = await resumableBottleTimerSession(
      repository: repo,
      now: start,
    );
    expect(result, isNull);
    expect(repo.clears, 1);
  });
}
```

- [ ] **Step 2 : lancer, constater l'échec**

Run: `flutter test test/features/events/domain/entities/bottle_timer_session_test.dart test/features/events/domain/use_cases/resumable_bottle_timer_session_test.dart`
Expected: FAIL (fichiers importés inexistants).

- [ ] **Step 3 : implémentation**

`lib/features/events/domain/entities/bottle_timer_session.dart` :

```dart
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_timer_session.freezed.dart';

/// Au-delà, un minuteur interrompu n'est plus repris.
const bottleTimerSessionExpiry = Duration(hours: 12);

/// Minuteur de biberon en cours et brouillon du soin, persistés pour
/// reprendre après une app tuée.
@freezed
abstract class BottleTimerSession with _$BottleTimerSession {
  const BottleTimerSession._();

  const factory BottleTimerSession({
    required BottleTimerRun run,
    required CareEvent draft,

    /// Minuteur lancé depuis l'édition d'un soin existant.
    required bool editing,
  }) = _BottleTimerSession;

  /// `true` si le minuteur a été lancé il y a plus de 12 h.
  bool isExpiredAt(DateTime now) =>
      now.difference(run.startedAt) > bottleTimerSessionExpiry;
}
```

`lib/features/events/domain/repositories/bottle_timer_session_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:fpdart/fpdart.dart';

/// Stockage local de la session du minuteur de biberon (une au plus).
abstract interface class BottleTimerSessionRepository {
  Future<Either<Failure, void>> save(BottleTimerSession session);

  /// `null` si aucune session n'est enregistrée.
  Future<Either<Failure, BottleTimerSession?>> load();

  Future<Either<Failure, void>> clear();
}
```

`lib/features/events/domain/use_cases/resumable_bottle_timer_session.dart` :

```dart
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/repositories/bottle_timer_session_repository.dart';

/// Session à reprendre au démarrage ; efface une session expirée ou illisible.
Future<BottleTimerSession?> resumableBottleTimerSession({
  required BottleTimerSessionRepository repository,
  required DateTime now,
}) async {
  final loaded = await repository.load();
  final session = loaded.getOrElse((_) => null);
  if (session != null && !session.isExpiredAt(now)) return session;
  if (loaded.isLeft() || session != null) await repository.clear();
  return null;
}
```

Run: `dart run build_runner build -d`

- [ ] **Step 4 : tests verts**

Run: même commande qu'au Step 2. Expected: PASS.

- [ ] **Step 5 : commit**

```bash
git add lib/features/events/domain/entities/bottle_timer_session.dart lib/features/events/domain/entities/bottle_timer_session.freezed.dart lib/features/events/domain/repositories/bottle_timer_session_repository.dart lib/features/events/domain/use_cases/resumable_bottle_timer_session.dart test/helpers/in_memory_bottle_timer_session_repository.dart test/features/events/domain/entities/bottle_timer_session_test.dart test/features/events/domain/use_cases/resumable_bottle_timer_session_test.dart
git commit -m "feat: session du minuteur de biberon et règle de reprise"
```

(Vérifier avec `git status` si les `.freezed.dart` sont versionnés dans ce dépôt ; ne les ajouter que s'ils le sont.)

---

### Task 2 : DTO JSON et repository `shared_preferences`

**Files:**
- Create: `lib/features/events/data/dtos/bottle_timer_session_dto.dart`
- Create: `lib/features/events/data/repositories/prefs_bottle_timer_session_repository.dart`
- Create: `lib/features/events/presentation/providers/bottle_timer_session_providers.dart`
- Test: `test/features/events/data/prefs_bottle_timer_session_repository_test.dart`

- [ ] **Step 1 : test rouge**

```dart
import 'package:colette/features/events/data/repositories/prefs_bottle_timer_session_repository.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  final start = DateTime(2026, 9, 28, 2, 5);
  final session = BottleTimerSession(
    run: BottleTimerRun(
      startedAt: start,
      feedingEndsAt: start.add(const Duration(minutes: 21)),
    ),
    draft: makeEvent(startAt: start).copyWith(
      bottleMl: 150,
      pee: true,
      note: 'rot',
    ),
    editing: true,
  );

  Future<PrefsBottleTimerSessionRepository> repoWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    return PrefsBottleTimerSessionRepository(
      await SharedPreferences.getInstance(),
    );
  }

  test('sans session : Right(null)', () async {
    final repo = await repoWith({});
    expect((await repo.load()).toNullable(), isNull);
    expect((await repo.load()).isRight(), isTrue);
  });

  test('save puis load : aller-retour complet', () async {
    final repo = await repoWith({});
    await repo.save(session);
    expect((await repo.load()).toNullable(), session);
  });

  test('clear efface la session', () async {
    final repo = await repoWith({});
    await repo.save(session);
    await repo.clear();
    expect((await repo.load()).toNullable(), isNull);
  });

  test('JSON corrompu : Left', () async {
    final repo = await repoWith({
      PrefsBottleTimerSessionRepository.key: '{"run":',
    });
    expect((await repo.load()).isLeft(), isTrue);
  });
}
```

- [ ] **Step 2 : lancer, constater l'échec**

Run: `flutter test test/features/events/data/prefs_bottle_timer_session_repository_test.dart`
Expected: FAIL (import manquant).

- [ ] **Step 3 : implémentation**

`lib/features/events/data/dtos/bottle_timer_session_dto.dart` :

```dart
import 'dart:convert';

import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Conversion `BottleTimerSession` ↔ JSON local (dates en millisecondes).
abstract final class BottleTimerSessionDto {
  static String encode(BottleTimerSession session) => jsonEncode({
    'startedAt': _ms(session.run.startedAt),
    'feedingEndsAt': _ms(session.run.feedingEndsAt),
    'editing': session.editing,
    'draft': _draftToMap(session.draft),
  });

  /// Lève une exception si [raw] est illisible (convertie par `guard()`).
  static BottleTimerSession decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return BottleTimerSession(
      run: BottleTimerRun(
        startedAt: _date(map['startedAt']),
        feedingEndsAt: _date(map['feedingEndsAt']),
      ),
      editing: map['editing'] as bool,
      draft: _draftFromMap(map['draft'] as Map<String, dynamic>),
    );
  }

  static int _ms(DateTime date) => date.millisecondsSinceEpoch;

  static DateTime _date(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms! as int);

  static Map<String, dynamic> _draftToMap(CareEvent e) => {
    'id': e.id,
    'startAt': _ms(e.startAt),
    'endAt': _ms(e.endAt),
    'pee': e.pee,
    'poop': e.poop,
    'diaperChange': e.diaperChange,
    'adrigyl': e.adrigyl,
    'bath': e.bath,
    'eyeCare': e.eyeCare,
    'noseCare': e.noseCare,
    'umbilicalCare': e.umbilicalCare,
    'bottleMl': e.bottleMl,
    'note': e.note,
    'createdByDeviceId': e.createdByDeviceId,
    'createdAt': _ms(e.createdAt),
    'updatedAt': _ms(e.updatedAt),
  };

  static CareEvent _draftFromMap(Map<String, dynamic> m) => CareEvent(
    id: m['id'] as String,
    startAt: _date(m['startAt']),
    endAt: _date(m['endAt']),
    pee: m['pee'] as bool,
    poop: m['poop'] as bool,
    diaperChange: m['diaperChange'] as bool,
    adrigyl: m['adrigyl'] as bool,
    bath: m['bath'] as bool,
    eyeCare: m['eyeCare'] as bool,
    noseCare: m['noseCare'] as bool,
    umbilicalCare: m['umbilicalCare'] as bool,
    bottleMl: m['bottleMl'] as int?,
    note: m['note'] as String?,
    createdByDeviceId: m['createdByDeviceId'] as String,
    createdAt: _date(m['createdAt']),
    updatedAt: _date(m['updatedAt']),
  );
}
```

`lib/features/events/data/repositories/prefs_bottle_timer_session_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/events/data/dtos/bottle_timer_session_dto.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/repositories/bottle_timer_session_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session du minuteur dans `shared_preferences` (clé [key]).
class PrefsBottleTimerSessionRepository
    implements BottleTimerSessionRepository {
  PrefsBottleTimerSessionRepository(this._prefs);

  static const key = 'bottle_timer_session';

  final SharedPreferences _prefs;

  @override
  Future<Either<Failure, void>> save(BottleTimerSession session) =>
      guard(() => _prefs.setString(key, BottleTimerSessionDto.encode(session)));

  @override
  Future<Either<Failure, BottleTimerSession?>> load() => guard(() async {
    final raw = _prefs.getString(key);
    return raw == null ? null : BottleTimerSessionDto.decode(raw);
  });

  @override
  Future<Either<Failure, void>> clear() => guard(() => _prefs.remove(key));
}
```

`lib/features/events/presentation/providers/bottle_timer_session_providers.dart` :

```dart
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/events/data/repositories/prefs_bottle_timer_session_repository.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/repositories/bottle_timer_session_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottle_timer_session_providers.g.dart';

/// Stockage local de la session du minuteur ; remplacé en test.
@Riverpod(keepAlive: true)
BottleTimerSessionRepository bottleTimerSessionRepository(Ref ref) =>
    PrefsBottleTimerSessionRepository(ref.watch(sharedPreferencesProvider));

/// Session interrompue à rouvrir sur Aujourd'hui, posée au démarrage par
/// `BottleTimerResumeGate` et consommée par `DashboardPage`.
@Riverpod(keepAlive: true)
class BottleTimerResume extends _$BottleTimerResume {
  @override
  BottleTimerSession? build() => null;

  void offer(BottleTimerSession session) => state = session;

  /// Renvoie la session proposée et l'efface.
  BottleTimerSession? take() {
    final session = state;
    state = null;
    return session;
  }
}
```

Run: `dart run build_runner build -d`

- [ ] **Step 4 : test vert**

Run: `flutter test test/features/events/data/prefs_bottle_timer_session_repository_test.dart`
Expected: PASS.

- [ ] **Step 5 : commit**

```bash
git add lib/features/events/data/dtos/bottle_timer_session_dto.dart lib/features/events/data/repositories/prefs_bottle_timer_session_repository.dart lib/features/events/presentation/providers/bottle_timer_session_providers.dart lib/features/events/presentation/providers/bottle_timer_session_providers.g.dart test/features/events/data/prefs_bottle_timer_session_repository_test.dart
git commit -m "feat: persistance locale de la session du minuteur de biberon"
```

---

### Task 3 : pont `BottleTimerSystem` et fakes par défaut en test

**Files:**
- Create: `lib/core/device/bottle_timer_system.dart`
- Create: `test/helpers/fake_bottle_timer_system.dart`
- Modify: `test/helpers/pump_app.dart`, `test/helpers/colette_app_overrides.dart`

- [ ] **Step 1 : implémentation** (pas de logique à tester : un appel de canal, sur le modèle de `NativeDeviceFeedback`)

`lib/core/device/bottle_timer_system.dart` :

```dart
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottle_timer_system.g.dart';

/// Présence du minuteur de biberon hors de l'app : Live Activity (iOS 16.1+)
/// et notifications locales de fin de phase.
abstract interface class BottleTimerSystem {
  /// Crée ou met à jour l'activité et reprogramme les notifications.
  Future<void> sync({
    required DateTime startedAt,
    required DateTime feedingEndsAt,
    required DateTime uprightEndsAt,
    required String babyName,
  });

  /// Termine l'activité et retire les notifications.
  Future<void> clear();
}

/// Pont Swift `colette/bottle-timer` (voir `BottleTimerChannel.swift`).
final class NativeBottleTimerSystem implements BottleTimerSystem {
  const NativeBottleTimerSystem(this._channel);

  static const channelName = 'colette/bottle-timer';

  final MethodChannel _channel;

  @override
  Future<void> sync({
    required DateTime startedAt,
    required DateTime feedingEndsAt,
    required DateTime uprightEndsAt,
    required String babyName,
  }) => _invoke('sync', {
    'startedAt': startedAt.millisecondsSinceEpoch,
    'feedingEndsAt': feedingEndsAt.millisecondsSinceEpoch,
    'uprightEndsAt': uprightEndsAt.millisecondsSinceEpoch,
    'babyName': babyName,
  });

  @override
  Future<void> clear() => _invoke('clear', null);

  /// L'affichage hors de l'app est un bonus : l'échec est seulement logué.
  Future<void> _invoke(String method, Object? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on Exception catch (error, stackTrace) {
      log(
        'colette/bottle-timer $method a échoué',
        name: 'colette',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Pont du minuteur hors de l'app ; remplacé par un faux dans les tests.
@Riverpod(keepAlive: true)
BottleTimerSystem bottleTimerSystem(Ref ref) =>
    const NativeBottleTimerSystem(MethodChannel(NativeBottleTimerSystem.channelName));
```

`test/helpers/fake_bottle_timer_system.dart` :

```dart
import 'package:colette/core/device/bottle_timer_system.dart';

/// Enregistre les appels : `sync:<fin du biberon>|<prénom>` et `clear`.
class FakeBottleTimerSystem implements BottleTimerSystem {
  final calls = <String>[];

  @override
  Future<void> sync({
    required DateTime startedAt,
    required DateTime feedingEndsAt,
    required DateTime uprightEndsAt,
    required String babyName,
  }) async => calls.add('sync:${feedingEndsAt.toIso8601String()}|$babyName');

  @override
  Future<void> clear() async => calls.add('clear');
}
```

Dans `test/helpers/pump_app.dart`, ajouter les deux fakes par défaut (comme `isOnlineProvider`) :

```dart
  bool overridden(Object provider) =>
      overrides.any((override) => override.origin == provider);
  ...
      overrides: [
        if (!overridden(isOnlineProvider))
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
        if (!overridden(bottleTimerSystemProvider))
          bottleTimerSystemProvider.overrideWithValue(FakeBottleTimerSystem()),
        if (!overridden(bottleTimerSessionRepositoryProvider))
          bottleTimerSessionRepositoryProvider.overrideWithValue(
            InMemoryBottleTimerSessionRepository(),
          ),
        ...overrides,
      ],
```

(remplace `hasOnlineOverride` ; imports : `bottle_timer_system.dart`, `bottle_timer_session_providers.dart`, `fake_bottle_timer_system.dart`, `in_memory_bottle_timer_session_repository.dart`.)

Dans `test/helpers/colette_app_overrides.dart`, ajouter un paramètre `BottleTimerSystem? bottleTimerSystem` et l'override `bottleTimerSystemProvider.overrideWithValue(bottleTimerSystem ?? FakeBottleTimerSystem())` (la session reste en `shared_preferences` mockées).

Run: `dart run build_runner build -d && flutter test`
Expected: PASS (aucun comportement changé).

- [ ] **Step 2 : commit**

```bash
git add lib/core/device/bottle_timer_system.dart lib/core/device/bottle_timer_system.g.dart test/helpers/fake_bottle_timer_system.dart test/helpers/pump_app.dart test/helpers/colette_app_overrides.dart
git commit -m "feat: pont natif colette/bottle-timer pour le minuteur hors de l'app"
```

---

### Task 4 : `restore` et effets `sync` / `clear`

**Files:**
- Modify: `lib/features/events/presentation/providers/bottle_timer_controller.dart`
- Test: `test/features/events/presentation/bottle_timer_controller_test.dart`

- [ ] **Step 1 : tests rouges**

Dans le `setUp`, ajouter `system = FakeBottleTimerSystem();`, `sessions = InMemoryBottleTimerSessionRepository();` et les overrides :

```dart
        bottleTimerSystemProvider.overrideWithValue(system),
        bottleTimerSessionRepositoryProvider.overrideWithValue(sessions),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(
            BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
          ),
        ),
```

(adapter les champs requis de `BabyProfile` à son constructeur) et `container.listen(babyProfileProvider, (_, _) {});` pour charger le profil. Nouveau groupe :

```dart
  group('présence hors de l\'app', () {
    test('restore remet le minuteur sans changer ses dates', () {
      final run = BottleTimerRun.startingAt(start.subtract(const Duration(minutes: 5)));
      controller().restore(run);
      expect(container.read(bottleTimerControllerProvider), run);
    });

    test('lancement puis « Biberon terminé » : sync à chaque fois', () async {
      container.listen(bottleTimerEffectsProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      controller().start();
      clock.current = start.add(const Duration(minutes: 10));
      controller().skipToUpright();
      await Future<void>.delayed(Duration.zero);
      expect(system.calls, [
        'sync:${start.add(const Duration(minutes: 30)).toIso8601String()}|Colette',
        'sync:${start.add(const Duration(minutes: 10)).toIso8601String()}|Colette',
      ]);
    });

    test('arrêt : clear et session effacée', () async {
      container.listen(bottleTimerEffectsProvider, (_, _) {});
      controller().start();
      controller().reset();
      await Future<void>.delayed(Duration.zero);
      expect(system.calls.last, 'clear');
      expect(sessions.clears, 1);
    });

    test('destruction des effets : clear et session effacée', () async {
      final sub = container.listen(bottleTimerEffectsProvider, (_, _) {});
      controller().start();
      sub.close();
      await container.pump();
      expect(system.calls.last, 'clear');
      expect(sessions.clears, 1);
    });
  });
```

- [ ] **Step 2 : lancer, constater l'échec**

Run: `flutter test test/features/events/presentation/bottle_timer_controller_test.dart`
Expected: FAIL (`restore` inexistant).

- [ ] **Step 3 : implémentation**

Dans `BottleTimerController` :

```dart
  /// Remet un minuteur interrompu (app tuée) sans changer ses dates.
  void restore(BottleTimerRun run) => state = run;
```

`bottleTimerEffects` devient :

```dart
/// Écran maintenu allumé, sons et vibrations aux transitions du minuteur ;
/// Live Activity et notifications tenues à jour. À sa destruction (fermeture
/// du formulaire) : écran relâché, activité fermée, session effacée.
@riverpod
void bottleTimerEffects(Ref ref) {
  final feedback = ref.watch(deviceFeedbackProvider);
  final system = ref.watch(bottleTimerSystemProvider);
  final sessions = ref.watch(bottleTimerSessionRepositoryProvider);
  Future<void> release() async {
    await system.clear();
    await sessions.clear();
  }

  ref
    ..listen(bottleTimerPhaseProvider, (previous, next) {
      // … switch existant inchangé …
    })
    ..listen(bottleTimerControllerProvider, (previous, next) {
      if (next != null && next != previous) {
        unawaited(
          system.sync(
            startedAt: next.startedAt,
            feedingEndsAt: next.feedingEndsAt,
            uprightEndsAt: next.uprightEndsAt,
            babyName: ref.read(babyProfileProvider).value?.name ?? '',
          ),
        );
      } else if (next == null && previous != null) {
        unawaited(release());
      }
    })
    ..onDispose(() {
      unawaited(feedback.setKeepScreenOn(false));
      unawaited(release());
    });
}
```

Imports : `bottle_timer_system.dart`, `bottle_timer_session_providers.dart`, `baby_providers.dart`.

Run: `dart run build_runner build -d`

- [ ] **Step 4 : tests verts**

Run: `flutter test test/features/events/presentation/`
Expected: PASS.

- [ ] **Step 5 : commit**

```bash
git add lib/features/events/presentation/providers/bottle_timer_controller.dart lib/features/events/presentation/providers/bottle_timer_controller.g.dart test/features/events/presentation/bottle_timer_controller_test.dart
git commit -m "feat: le minuteur de biberon tient à jour la Live Activity et les notifications"
```

---

### Task 5 : feuille — persistance du brouillon et reprise

**Files:**
- Create: `lib/features/events/presentation/widgets/bottle_timer_stop_dialog.dart`
- Modify: `lib/features/events/presentation/widgets/event_form_sheet.dart`
- Test: `test/features/events/presentation/event_form_sheet_timer_test.dart`

- [ ] **Step 1 : tests rouges**

Dans `event_form_sheet_timer_test.dart` : `late InMemoryBottleTimerSessionRepository sessions;` créé dans `setUp`, override `bottleTimerSessionRepositoryProvider.overrideWithValue(sessions)` dans `openSheet`, et un paramètre optionnel `BottleTimerSession? restored` transmis à `showEventFormSheet(context, restored: restored)`. Tests :

```dart
  testWidgets('pendant le minuteur, le brouillon est sauvegardé', (
    tester,
  ) async {
    await openSheet(tester);
    await enableBottleAndStart(tester);
    expect(sessions.session?.run.startedAt, now);
    expect(sessions.session?.draft.bottleMl, 120);
    await tester.tap(find.text('Pipi'));
    await tester.pump();
    expect(sessions.session?.draft.pee, isTrue);
    expect(sessions.session?.editing, isFalse);
  });

  testWidgets('session reprise en cours : minuteur et brouillon restaurés', (
    tester,
  ) async {
    final run = BottleTimerRun.startingAt(
      now.subtract(const Duration(minutes: 10)),
    );
    await openSheet(
      tester,
      restored: BottleTimerSession(
        run: run,
        draft: makeEvent(startAt: run.startedAt).copyWith(bottleMl: 90),
        editing: false,
      ),
    );
    await tester.pump();
    expect(find.text('Biberon'), findsWidgets);
    expect(find.text('90 ml'), findsOneWidget);
    expect(find.text('Arrêter'), findsOneWidget);
    verifyNever(() => repo.save(any(), any()));
  });

  testWidgets('session reprise terminée : soin enregistré et feuille fermée', (
    tester,
  ) async {
    final run = BottleTimerRun.startingAt(
      now.subtract(const Duration(minutes: 50)),
    );
    await openSheet(
      tester,
      restored: BottleTimerSession(
        run: run,
        draft: makeEvent(startAt: run.startedAt).copyWith(bottleMl: 90),
        editing: false,
      ),
    );
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
            as CareEvent;
    expect(saved.startAt, run.startedAt);
    expect(saved.endAt, run.feedingEndsAt);
    expect(saved.bottleMl, 90);
    expect(find.byType(EventFormSheet), findsNothing);
    expect(feedback.calls, isNot(contains('sound:uprightEnded')));
  });

  testWidgets('session reprise en édition : titre de modification', (
    tester,
  ) async {
    final run = BottleTimerRun.startingAt(now);
    await openSheet(
      tester,
      restored: BottleTimerSession(
        run: run,
        draft: makeEvent(startAt: now).copyWith(bottleMl: 90),
        editing: true,
      ),
    );
    expect(find.text('Modifier'), findsOneWidget);
  });
```

Vérifier dans `lib/l10n/app_fr.arb` les libellés exacts (`careTypePee`, `eventFormEditTitle`, format de la quantité dans `BottleField`) et ajuster `'Pipi'`, `'Modifier'`, `'90 ml'` en conséquence.

- [ ] **Step 2 : lancer, constater l'échec**

Run: `flutter test test/features/events/presentation/event_form_sheet_timer_test.dart`
Expected: FAIL (`restored` inexistant).

- [ ] **Step 3 : implémentation**

`bottle_timer_stop_dialog.dart` : déplacer le `showDialog` de `_confirmClose` :

```dart
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Demande s'il faut arrêter le minuteur en cours ; `true` pour arrêter.
Future<bool> confirmBottleTimerStop(BuildContext context) async {
  final s = S.of(context);
  final stop = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.bottleTimerCloseTitle),
      content: Text(s.bottleTimerCloseBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.bottleTimerContinue),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(s.bottleTimerStop),
        ),
      ],
    ),
  );
  return stop ?? false;
}
```

`event_form_sheet.dart` :

- `showEventFormSheet(…, BottleTimerSession? restored)` transmis à `EventFormSheet(restored: restored)` ; champ `final BottleTimerSession? restored;` documenté « Minuteur interrompu à reprendre (app tuée) ».
- `bool get _isEditing => widget.initial != null || (widget.restored?.editing ?? false);`
- `initState` :

```dart
    final restored = widget.restored;
    _draft =
        restored?.draft ??
        widget.initial ??
        newEventDraft(…);
    _noteController = TextEditingController(text: _draft.note ?? '')
      ..addListener(_persistSession);
    if (restored != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resume(restored.run));
    }
```

- nouvelles méthodes :

```dart
  /// Reprend le minuteur ; s'il a fini pendant que l'app était tuée,
  /// enregistre sans son (les notifications ont déjà sonné).
  void _resume(BottleTimerRun run) {
    if (!mounted) return;
    ref.read(bottleTimerControllerProvider.notifier).restore(run);
    final now = ref.read(clockProvider).now();
    if (computeBottleTimerPhase(run: run, now: now) is BottleTimerDone) {
      _autoSave();
    }
  }

  void _setDraft(CareEvent draft) {
    setState(() => _draft = draft);
    _persistSession();
  }

  /// Sauvegarde minuteur et brouillon tant que le minuteur tourne.
  void _persistSession() {
    final run = ref.read(bottleTimerControllerProvider);
    if (run == null) return;
    final note = _noteController.text.trim();
    unawaited(
      ref.read(bottleTimerSessionRepositoryProvider).save(
        BottleTimerSession(
          run: run,
          draft: _draft.copyWith(note: note.isEmpty ? null : note),
          editing: _isEditing,
        ),
      ),
    );
  }
```

- `_pickTime`, les `CareChip` et `BottleField` passent par `_setDraft(…)` au lieu de `setState(() => _draft = …)` (`_autoSave` garde son `setState`).
- `_confirmClose` :

```dart
  Future<void> _confirmClose() async {
    if (!await confirmBottleTimerStop(context) || !mounted) return;
    ref.read(bottleTimerControllerProvider.notifier).reset();
    Navigator.of(context).pop();
  }
```

- dans `build`, à côté du `listen` de phase :

```dart
      ..listen(bottleTimerControllerProvider, (_, run) {
        if (run != null) _persistSession();
      })
```

Imports : `dart:async`, `bottle_timer_run.dart`, `bottle_timer_session.dart`, `bottle_timer_session_providers.dart`, `bottle_timer_stop_dialog.dart`. Le fichier doit rester sous 300 lignes (`wc -l`).

- [ ] **Step 4 : tests verts**

Run: `flutter test test/features/events/`
Expected: PASS.

- [ ] **Step 5 : commit**

```bash
git add lib/features/events/presentation/widgets/bottle_timer_stop_dialog.dart lib/features/events/presentation/widgets/event_form_sheet.dart test/features/events/presentation/event_form_sheet_timer_test.dart
git commit -m "feat: le formulaire sauvegarde et reprend le minuteur de biberon"
```

---

### Task 6 : gate de reprise et ouverture sur Aujourd'hui

**Files:**
- Create: `lib/app/bottle_timer_resume_gate.dart`
- Modify: `lib/app/colette_app.dart`, `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Test: `test/app/bottle_timer_resume_gate_test.dart`

- [ ] **Step 1 : tests rouges**

```dart
import 'package:colette/app/colette_app.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_session_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_event_factory.dart';
import '../helpers/colette_app_overrides.dart';
import '../helpers/fake_bottle_timer_system.dart';
import '../helpers/in_memory_bottle_timer_session_repository.dart';

void main() {
  final now = DateTime(2026, 9, 28, 3);

  Future<void> pumpColetteApp(
    WidgetTester tester, {
    required InMemoryBottleTimerSessionRepository sessions,
    required FakeBottleTimerSystem system,
    String? code = 'ABCDEFGH',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await coletteAppOverrides(
            householdCode: code,
            deviceId: 'dev-1',
            bottleTimerSystem: system,
          ),
          bottleTimerSessionRepositoryProvider.overrideWithValue(sessions),
          clockProvider.overrideWithValue(FixedClock(now)),
          bottleTimerTickProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const ColetteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  BottleTimerSession sessionStartedAgo(Duration ago) {
    final run = BottleTimerRun.startingAt(now.subtract(ago));
    return BottleTimerSession(
      run: run,
      draft: makeEvent(startAt: run.startedAt).copyWith(bottleMl: 90),
      editing: false,
    );
  }

  testWidgets('sans session : activité orpheline fermée, pas de formulaire', (
    tester,
  ) async {
    final system = FakeBottleTimerSystem();
    await pumpColetteApp(
      tester,
      sessions: InMemoryBottleTimerSessionRepository(),
      system: system,
    );
    expect(system.calls, contains('clear'));
    expect(find.byType(EventFormSheet), findsNothing);
  });

  testWidgets('session en cours : formulaire rouvert', (tester) async {
    final sessions = InMemoryBottleTimerSessionRepository(
      session: sessionStartedAgo(const Duration(minutes: 10)),
    );
    await pumpColetteApp(
      tester,
      sessions: sessions,
      system: FakeBottleTimerSystem(),
    );
    expect(find.byType(EventFormSheet), findsOneWidget);
  });

  testWidgets('session expirée : effacée, pas de formulaire', (tester) async {
    final sessions = InMemoryBottleTimerSessionRepository(
      session: sessionStartedAgo(const Duration(hours: 13)),
    );
    await pumpColetteApp(
      tester,
      sessions: sessions,
      system: FakeBottleTimerSystem(),
    );
    expect(sessions.session, isNull);
    expect(find.byType(EventFormSheet), findsNothing);
  });

  testWidgets('sans foyer : rien n\'est repris', (tester) async {
    final sessions = InMemoryBottleTimerSessionRepository(
      session: sessionStartedAgo(const Duration(minutes: 10)),
    );
    await pumpColetteApp(
      tester,
      sessions: sessions,
      system: FakeBottleTimerSystem(),
      code: null,
    );
    expect(find.byType(EventFormSheet), findsNothing);
    expect(sessions.session, isNotNull);
  });
}
```

(Si `SplashIntro` retarde le contenu, reprendre ce que fait `notifications_gate_test.dart` ; si `FixedClock` n'a pas ce nom, utiliser la classe de test d'horloge du projet.)

- [ ] **Step 2 : lancer, constater l'échec**

Run: `flutter test test/app/bottle_timer_resume_gate_test.dart`
Expected: FAIL (le formulaire n'est jamais rouvert ; `clear` absent).

- [ ] **Step 3 : implémentation**

`lib/app/bottle_timer_resume_gate.dart` :

```dart
import 'dart:async';

import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/device/bottle_timer_system.dart';
import 'package:colette/features/events/domain/use_cases/resumable_bottle_timer_session.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_session_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Au démarrage, rouvre un minuteur de biberon interrompu (app tuée) sur
/// Aujourd'hui, ou ferme une Live Activity orpheline.
class BottleTimerResumeGate extends ConsumerStatefulWidget {
  const BottleTimerResumeGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BottleTimerResumeGate> createState() =>
      _BottleTimerResumeGateState();
}

class _BottleTimerResumeGateState extends ConsumerState<BottleTimerResumeGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentHouseholdCodeProvider, fireImmediately: true, (
      _,
      code,
    ) {
      if (code == null || _checked) return;
      _checked = true;
      unawaited(_resume());
    });
  }

  Future<void> _resume() async {
    final session = await resumableBottleTimerSession(
      repository: ref.read(bottleTimerSessionRepositoryProvider),
      now: ref.read(clockProvider).now(),
    );
    if (!mounted) return;
    if (session == null) {
      await ref.read(bottleTimerSystemProvider).clear();
      return;
    }
    ref.read(bottleTimerResumeProvider.notifier).offer(session);
    ref.read(appRouterProvider).go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

`colette_app.dart` : `NotificationsGate(child: BottleTimerResumeGate(child: HealthSyncGate(…)))`.

`dashboard_page.dart`, dans `initState` après l'écoute de `bottleFormRequestProvider` :

```dart
    ref.listenManual(bottleTimerResumeProvider, fireImmediately: true, (
      _,
      session,
    ) {
      if (session == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final restored = ref.read(bottleTimerResumeProvider.notifier).take();
        if (restored != null) showEventFormSheet(context, restored: restored);
      });
    });
```

- [ ] **Step 4 : tests verts**

Run: `flutter test test/app/`
Expected: PASS.

- [ ] **Step 5 : commit**

```bash
git add lib/app/bottle_timer_resume_gate.dart lib/app/colette_app.dart lib/features/dashboard/presentation/pages/dashboard_page.dart test/app/bottle_timer_resume_gate_test.dart
git commit -m "feat: reprise du minuteur de biberon au démarrage"
```

---

### Task 7 : canal Swift et notifications locales

**Files:**
- Create: `ios/Runner/BottleTimer/BottleTimerAttributes.swift`
- Create: `ios/Runner/BottleTimer/BottleTimerChannel.swift`
- Modify: `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`

- [ ] **Step 1 : `BottleTimerAttributes.swift`** (partagé avec l'extension en Task 8)

```swift
import ActivityKit
import Foundation

/// Live Activity du minuteur de biberon : prénom fixe, dates dynamiques.
@available(iOS 16.1, *)
struct BottleTimerAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var startedAt: Date
    var feedingEndsAt: Date
    var uprightEndsAt: Date
  }

  var babyName: String
}
```

- [ ] **Step 2 : `BottleTimerChannel.swift`**

```swift
import ActivityKit
import Flutter
import UserNotifications

/// Canal `colette/bottle-timer` : Live Activity (iOS 16.1+) et notifications
/// locales de fin de phase du minuteur de biberon.
enum BottleTimerChannel {
  static let notificationPrefix = "bottle-timer."
  private static let feedingId = "bottle-timer.feeding"
  private static let uprightId = "bottle-timer.upright"

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "BottleTimerPlugin")?.messenger() else {
      return
    }
    let channel = FlutterMethodChannel(name: "colette/bottle-timer", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "sync":
        guard let args = call.arguments as? [String: Any],
          let startedAt = date(args["startedAt"]),
          let feedingEndsAt = date(args["feedingEndsAt"]),
          let uprightEndsAt = date(args["uprightEndsAt"])
        else {
          result(FlutterError(code: "bad-args", message: nil, details: nil))
          return
        }
        let babyName = args["babyName"] as? String ?? ""
        scheduleNotifications(feedingEndsAt: feedingEndsAt, uprightEndsAt: uprightEndsAt)
        if #available(iOS 16.1, *) {
          Task {
            await syncActivity(
              babyName: babyName,
              state: .init(startedAt: startedAt, feedingEndsAt: feedingEndsAt, uprightEndsAt: uprightEndsAt))
          }
        }
        result(nil)
      case "clear":
        clearNotifications()
        if #available(iOS 16.1, *) {
          Task { await endActivities() }
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func date(_ value: Any?) -> Date? {
    guard let ms = value as? NSNumber else { return nil }
    return Date(timeIntervalSince1970: ms.doubleValue / 1000)
  }

  // MARK: - Notifications

  private static func scheduleNotifications(feedingEndsAt: Date, uprightEndsAt: Date) {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [feedingId, uprightId])
    add(
      id: feedingId, at: feedingEndsAt,
      title: NSLocalizedString("bottleTimer.feedingEnded.title", comment: ""),
      body: NSLocalizedString("bottleTimer.feedingEnded.body", comment: ""))
    add(
      id: uprightId, at: uprightEndsAt,
      title: NSLocalizedString("bottleTimer.uprightEnded.title", comment: ""),
      body: NSLocalizedString("bottleTimer.uprightEnded.body", comment: ""))
  }

  private static func add(id: String, at date: Date, title: String, body: String) {
    let interval = date.timeIntervalSinceNow
    guard interval > 1 else { return }
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    if #available(iOS 15.0, *) { content.interruptionLevel = .timeSensitive }
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
    UNUserNotificationCenter.current().add(
      UNNotificationRequest(identifier: id, content: content, trigger: trigger))
  }

  private static func clearNotifications() {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [feedingId, uprightId])
    center.removeDeliveredNotifications(withIdentifiers: [feedingId, uprightId])
  }

  // MARK: - Live Activity

  @available(iOS 16.1, *)
  private static func syncActivity(babyName: String, state: BottleTimerAttributes.ContentState) async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    if let activity = Activity<BottleTimerAttributes>.activities.first {
      if #available(iOS 16.2, *) {
        await activity.update(ActivityContent(state: state, staleDate: state.uprightEndsAt))
      } else {
        await activity.update(using: state)
      }
      return
    }
    let attributes = BottleTimerAttributes(babyName: babyName)
    do {
      if #available(iOS 16.2, *) {
        _ = try Activity.request(
          attributes: attributes,
          content: ActivityContent(state: state, staleDate: state.uprightEndsAt))
      } else {
        _ = try Activity.request(attributes: attributes, contentState: state)
      }
    } catch {
      NSLog("colette: Live Activity refusée : \(error)")
    }
  }

  @available(iOS 16.1, *)
  private static func endActivities() async {
    for activity in Activity<BottleTimerAttributes>.activities {
      if #available(iOS 16.2, *) {
        await activity.end(nil, dismissalPolicy: .immediate)
      } else {
        await activity.end(using: nil, dismissalPolicy: .immediate)
      }
    }
  }
}
```

(`staleDate` n'existe qu'à partir d'iOS 16.2 ; sur 16.1 l'activité reste sur les décomptes à 0:00, acceptable.)

- [ ] **Step 3 : `AppDelegate.swift`**

```swift
import UserNotifications
…
  override func application(…) -> Bool {
    // Delegate posé avant `super` : `firebase_messaging` le garde et reçoit
    // ses appels via `FlutterAppDelegate` ; nos notifications de minuteur
    // sont filtrées dans `willPresent`.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(…) {
    …
    BottleTimerChannel.register(with: engineBridge.pluginRegistry)
  }

  /// Au premier plan, les sons de l'app remplacent les notifications du minuteur.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.identifier.hasPrefix(BottleTimerChannel.notificationPrefix) {
      completionHandler([])
      return
    }
    super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
  }
```

- [ ] **Step 4 : `Info.plist` et textes**

Ajouter `<key>NSSupportsLiveActivities</key><true/>` au `Info.plist` du Runner. Créer `ios/Runner/fr.lproj/Localizable.strings` (ou compléter s'il existe) :

```
"bottleTimer.feedingEnded.title" = "Biberon terminé";
"bottleTimer.feedingEnded.body" = "12 min à la verticale.";
"bottleTimer.uprightEnded.title" = "Verticale terminée";
"bottleTimer.uprightEnded.body" = "Ouvre Colette pour enregistrer le biberon.";
```

Ajouter les deux fichiers Swift et `Localizable.strings` à la target Runner (fait par le script de la Task 8, étape 1).

- [ ] **Step 5 : pas de commit séparé** : le projet Xcode n'est cohérent qu'après la Task 8 ; commit commun.

---

### Task 8 : Widget Extension `BottleTimerWidget`

**Files:**
- Create: `ios/scripts/add_bottle_timer_widget.rb`
- Create: `ios/BottleTimerWidget/BottleTimerWidgetBundle.swift`, `BottleTimerLiveActivity.swift`, `BottleTimerViews.swift`, `Info.plist`, `Assets.xcassets/…`, `fr.lproj/Localizable.strings`
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (via le script)

- [ ] **Step 1 : script `xcodeproj`** qui :
  - ajoute `Runner/BottleTimer/*.swift` et `Runner/fr.lproj/Localizable.strings` à la target Runner ;
  - crée la target `BottleTimerWidget` (`:app_extension`, iOS 16.1, bundle id `fr.montet.colette.BottleTimerWidget`, équipe `D2K5A7DBDQ`, signature automatique, Swift 5, `INFOPLIST_FILE = BottleTimerWidget/Info.plist`, `GENERATE_INFOPLIST_FILE = NO`, `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME` vide, `SKIP_INSTALL = YES`) avec `BottleTimerWidget/*.swift`, `Runner/BottleTimer/BottleTimerAttributes.swift`, `Assets.xcassets` et `fr.lproj/Localizable.strings`, frameworks `WidgetKit` et `SwiftUI` ;
  - ajoute au Runner une phase « Embed Foundation Extensions » (copy files, destination plugins) contenant `BottleTimerWidget.appex`, **placée avant « Thin Binary »**, et la dépendance de target ;
  - ajoute `fr` aux `knownRegions` si absent.

- [ ] **Step 2 : sources de l'extension**

`BottleTimerWidgetBundle.swift` :

```swift
import SwiftUI
import WidgetKit

@main
struct BottleTimerWidgetBundle: WidgetBundle {
  var body: some Widget {
    BottleTimerLiveActivity()
  }
}
```

`BottleTimerLiveActivity.swift` :

```swift
import ActivityKit
import SwiftUI
import WidgetKit

/// Minuteur de biberon dans le Dynamic Island et sur l'écran verrouillé.
struct BottleTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BottleTimerAttributes.self) { context in
      LockScreenView(babyName: context.attributes.babyName, state: context.state, isStale: context.isStale)
        .activityBackgroundTint(Color("Background"))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label("bottleTimer.feeding", systemImage: "waterbottle")
            .font(.subheadline)
            .foregroundStyle(Color("Feeding"))
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(context.attributes.babyName)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        DynamicIslandExpandedRegion(.bottom) {
          PhasesView(state: context.state, isStale: context.isStale, onDark: true)
        }
      } compactLeading: {
        Image(systemName: "waterbottle").foregroundStyle(Color("Feeding"))
      } compactTrailing: {
        Text(timerInterval: context.state.startedAt...context.state.uprightEndsAt, countsDown: true)
          .monospacedDigit()
          .frame(maxWidth: 44)
          .foregroundStyle(Color("Feeding"))
      } minimal: {
        Image(systemName: "waterbottle").foregroundStyle(Color("Feeding"))
      }
    }
  }
}
```

`BottleTimerViews.swift` :

```swift
import SwiftUI
import WidgetKit

/// Écran verrouillé : en-tête, puis les deux phases ou l'état terminé.
struct LockScreenView: View {
  let babyName: String
  let state: BottleTimerAttributes.ContentState
  let isStale: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label(
          babyName.isEmpty
            ? String(localized: "bottleTimer.feeding")
            : String(format: String(localized: "bottleTimer.titleFor %@"), babyName),
          systemImage: "waterbottle"
        )
        .font(.subheadline)
        .foregroundStyle(Color("Feeding"))
        Spacer()
        Text(state.startedAt, style: .time)
          .font(.caption)
          .foregroundStyle(Color("Secondary"))
      }
      PhasesView(state: state, isStale: isStale, onDark: false)
    }
    .padding(16)
  }
}

/// Deux décomptes côte à côte (biberon, verticale) ; « terminé » une fois périmé.
struct PhasesView: View {
  let state: BottleTimerAttributes.ContentState
  let isStale: Bool
  let onDark: Bool

  var body: some View {
    if isStale {
      VStack(alignment: .leading, spacing: 2) {
        Text("bottleTimer.done").font(.headline)
        Text("bottleTimer.openToSave").font(.caption).foregroundStyle(.secondary)
      }
    } else {
      HStack(alignment: .top, spacing: 12) {
        phase(
          "bottleTimer.feeding", from: state.startedAt, to: state.feedingEndsAt,
          color: Color("Feeding"))
          .layoutPriority(30)
        phase(
          "bottleTimer.upright", from: state.feedingEndsAt, to: state.uprightEndsAt,
          color: Color("Upright"))
          .layoutPriority(12)
      }
    }
  }

  private func phase(_ title: LocalizedStringKey, from: Date, to: Date, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.caption).foregroundStyle(onDark ? .secondary : Color("Secondary"))
      Text(timerInterval: from...to, countsDown: true)
        .font(.title2.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(color)
      ProgressView(timerInterval: from...to, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
        .tint(color)
    }
  }
}
```

`fr.lproj/Localizable.strings` (extension) :

```
"bottleTimer.feeding" = "Biberon";
"bottleTimer.upright" = "Verticale";
"bottleTimer.titleFor %@" = "Biberon de %@";
"bottleTimer.done" = "Minuteur terminé";
"bottleTimer.openToSave" = "Ouvre Colette pour enregistrer";
```

`Assets.xcassets` : couleurs `Feeding` (#A8573F / sombre #D08A6F), `Upright` (#57795D / #9DBBA2), `Background` (#FBF5EF / #1C1514), `Secondary` (#756059 / #B8A39B), reprises de `AppColors` (`categoryFeeding`, `success`, `pageBackground`, `textSecondary`).

`Info.plist` de l'extension : `CFBundleDisplayName` Colette, `CFBundleShortVersionString` `$(FLUTTER_BUILD_NAME)`, `CFBundleVersion` `$(FLUTTER_BUILD_NUMBER)`, `NSExtension` → `NSExtensionPointIdentifier` = `com.apple.widgetkit-extension`.

- [ ] **Step 3 : build**

Run: `ruby ios/scripts/add_bottle_timer_widget.rb && flutter build ios --simulator --debug`
Expected: build OK, sans « Cycle inside Runner ».

- [ ] **Step 4 : commit**

```bash
git add ios/scripts/add_bottle_timer_widget.rb ios/BottleTimerWidget ios/Runner/BottleTimer ios/Runner/fr.lproj ios/Runner/AppDelegate.swift ios/Runner/Info.plist ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat: Live Activity et notifications locales du minuteur de biberon (iOS)"
```

---

### Task 9 : vérification

- [ ] `dart format lib test && dart analyze && flutter test` : zéro erreur.
- [ ] Simulateur iPhone 17 Pro : lancer l'app, démarrer un minuteur, passer à l'accueil → îlot compact ; appui long → étendu ; verrouiller (Cmd+L) → écran verrouillé ; clair et sombre.
- [ ] Notifications : app en arrière-plan à la fin d'une phase (test rapide : temporairement, pas de modification de durée dans le code ; vérifier via `xcrun simctl` ou en patientant) ; masquées au premier plan.
- [ ] Tuer l'app pendant le minuteur, la relancer → feuille rouverte avec le brouillon.
- [ ] Notification FCM au premier plan toujours affichée (non régressée par le delegate).
