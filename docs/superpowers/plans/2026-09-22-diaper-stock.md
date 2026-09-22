# Stock de couches — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Saisir un stock de couches, le voir décroître à chaque change (et remonter si un change est supprimé), régler un seuil et afficher une alerte sur l'accueil sous ce seuil.

**Architecture:** Nouvelle feature `lib/features/diapers/` (domain, data, presentation). Le foyer stocke `diaperStock: { count, countedAt, alertThreshold, lastPackSize }` ; le restant est **dérivé** : `count − changes depuis countedAt`. Aucune écriture à la création, l'édition ou la suppression d'un événement. La feature `events` expose une méthode de comptage et un provider public `diaperChangesSince`.

**Tech Stack:** Flutter, Riverpod 3 codegen, freezed, fpdart, cloud_firestore, `fake_cloud_firestore`, `mocktail`, `pumpApp`.

Spec : `docs/superpowers/specs/2026-09-22-diaper-stock-design.md`.

**Conventions du projet à respecter dans chaque tâche :**

- Après toute modification d'un fichier annoté `@freezed` ou `@riverpod` : `dart run build_runner build -d`.
- Fin de tâche : `dart format lib test`, `dart analyze` (pas `flutter analyze`), `flutter test`.
- Commits en français, préfixes `feat:` / `test:` / `docs:`, avec `git add` explicite des fichiers de la tâche (le working tree peut contenir d'autres modifications en cours).
- Couleurs via `context.appColor(AppColors.xxx)`, espacements via `AppSpacing`, textes via `S.of(context)`.

**Précision par rapport à la spec :** le contrôleur reçoit le stock courant (et le restant) en paramètre plutôt que de le relire depuis un provider, comme `BabySettingsController.updateCareSettings(profile, settings)`. La sémantique (`recount`, `addPack`, `setThreshold`) est inchangée. La tâche 9 aligne la spec.

---

### Task 1 : Domaine — entités `DiaperStock`, `DiaperStockStatus` et use case

**Files:**
- Create: `lib/features/diapers/domain/entities/diaper_stock.dart`
- Create: `lib/features/diapers/domain/entities/diaper_stock_status.dart`
- Create: `lib/features/diapers/domain/use_cases/compute_diaper_stock_status.dart`
- Test: `test/features/diapers/domain/diaper_stock_test.dart`
- Test: `test/features/diapers/domain/compute_diaper_stock_status_test.dart`

- [ ] **Step 1 : Écrire les tests rouges**

`test/features/diapers/domain/diaper_stock_test.dart` :

```dart
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final countedAt = DateTime(2026, 9, 20, 10);
  final now = DateTime(2026, 9, 22, 15);
  final stock = DiaperStock(
    count: 44,
    countedAt: countedAt,
    alertThreshold: 12,
    lastPackSize: 30,
  );

  test('les défauts sont seuil 10 et paquet 44', () {
    final fresh = DiaperStock(count: 0, countedAt: countedAt);
    expect(fresh.alertThreshold, 10);
    expect(fresh.lastPackSize, 44);
  });

  test('recount pose count et countedAt, conserve seuil et paquet', () {
    final next = stock.recount(20, now: now);
    expect(next.count, 20);
    expect(next.countedAt, now);
    expect(next.alertThreshold, 12);
    expect(next.lastPackSize, 30);
  });

  test('addPack ajoute au restant, pose countedAt et mémorise la taille', () {
    final next = stock.addPack(50, remaining: 7, now: now);
    expect(next.count, 57);
    expect(next.countedAt, now);
    expect(next.lastPackSize, 50);
    expect(next.alertThreshold, 12);
  });
}
```

`test/features/diapers/domain/compute_diaper_stock_status_test.dart` :

```dart
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/use_cases/compute_diaper_stock_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeDiaperStockStatus();
  final countedAt = DateTime(2026, 9, 20, 10);

  test('restant = count − changes depuis le comptage', () {
    final status = compute(
      stock: DiaperStock(count: 44, countedAt: countedAt),
      changesSinceCount: 4,
    );
    expect(status.remaining, 40);
    expect(status.isLow, isFalse);
  });

  test('le restant est borné à 0', () {
    final status = compute(
      stock: DiaperStock(count: 3, countedAt: countedAt),
      changesSinceCount: 5,
    );
    expect(status.remaining, 0);
    expect(status.isLow, isTrue);
  });

  test('isLow est vrai strictement sous le seuil, faux au seuil', () {
    final stock = DiaperStock(count: 10, countedAt: countedAt);
    expect(compute(stock: stock, changesSinceCount: 0).isLow, isFalse);
    expect(compute(stock: stock, changesSinceCount: 1).isLow, isTrue);
  });

  test('un seuil à 0 désactive l\'alerte', () {
    final status = compute(
      stock: DiaperStock(count: 2, countedAt: countedAt, alertThreshold: 0),
      changesSinceCount: 2,
    );
    expect(status.remaining, 0);
    expect(status.isLow, isFalse);
  });
}
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run: `flutter test test/features/diapers/domain`
Expected: FAIL, imports introuvables (`diaper_stock.dart` n'existe pas).

- [ ] **Step 3 : Implémenter les entités et le use case**

`lib/features/diapers/domain/entities/diaper_stock.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'diaper_stock.freezed.dart';

/// Stock de couches : `count` couches comptées à l'instant `countedAt`.
@freezed
abstract class DiaperStock with _$DiaperStock {
  const DiaperStock._();

  const factory DiaperStock({
    required int count,
    required DateTime countedAt,
    @Default(10) int alertThreshold,
    @Default(44) int lastPackSize,
  }) = _DiaperStock;

  /// Nouveau comptage à [now] ; seuil et taille de paquet conservés.
  DiaperStock recount(int count, {required DateTime now}) =>
      copyWith(count: count, countedAt: now);

  /// Ajoute un paquet de [size] couches au [remaining] courant, à [now].
  DiaperStock addPack(
    int size, {
    required int remaining,
    required DateTime now,
  }) => copyWith(count: remaining + size, countedAt: now, lastPackSize: size);
}
```

`lib/features/diapers/domain/entities/diaper_stock_status.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'diaper_stock_status.freezed.dart';

/// Stock restant et signal d'alerte.
@freezed
abstract class DiaperStockStatus with _$DiaperStockStatus {
  const factory DiaperStockStatus({
    required int remaining,
    required bool isLow,
  }) = _DiaperStockStatus;
}
```

`lib/features/diapers/domain/use_cases/compute_diaper_stock_status.dart` :

```dart
import 'dart:math' as math;

import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';

/// Restant = `count − changes depuis countedAt`, borné à 0.
/// Alerte si le seuil est actif (> 0) et que le restant lui est strictement inférieur.
class ComputeDiaperStockStatus {
  const ComputeDiaperStockStatus();

  DiaperStockStatus call({
    required DiaperStock stock,
    required int changesSinceCount,
  }) {
    final remaining = math.max(0, stock.count - changesSinceCount);
    return DiaperStockStatus(
      remaining: remaining,
      isLow: stock.alertThreshold > 0 && remaining < stock.alertThreshold,
    );
  }
}
```

- [ ] **Step 4 : Générer et vérifier**

Run: `dart run build_runner build -d && flutter test test/features/diapers/domain`
Expected: PASS, 7 tests.

- [ ] **Step 5 : Commit**

```bash
git add lib/features/diapers/domain test/features/diapers/domain
git commit -m "feat: entité DiaperStock et calcul du stock restant"
```

---

### Task 2 : Data — repository, DTO et implémentation Firestore

**Files:**
- Create: `lib/features/diapers/domain/repositories/diaper_stock_repository.dart`
- Create: `lib/features/diapers/data/dtos/diaper_stock_dto.dart`
- Create: `lib/features/diapers/data/repositories/firestore_diaper_stock_repository.dart`
- Test: `test/features/diapers/data/diaper_stock_dto_test.dart`
- Test: `test/features/diapers/data/firestore_diaper_stock_repository_test.dart`

- [ ] **Step 1 : Écrire les tests rouges**

`test/features/diapers/data/diaper_stock_dto_test.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/diapers/data/dtos/diaper_stock_dto.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final countedAt = DateTime(2026, 9, 20, 10);

  test('aller-retour toMap / fromMap', () {
    final stock = DiaperStock(
      count: 44,
      countedAt: countedAt,
      alertThreshold: 8,
      lastPackSize: 30,
    );
    expect(DiaperStockDto.fromMap(DiaperStockDto.toMap(stock)), stock);
  });

  test('toMap écrit countedAt en Timestamp', () {
    final map = DiaperStockDto.toMap(
      DiaperStock(count: 1, countedAt: countedAt),
    );
    expect(map['countedAt'], Timestamp.fromDate(countedAt));
  });

  test('fromMap renvoie null sans countedAt', () {
    expect(DiaperStockDto.fromMap(const {'count': 44}), isNull);
  });

  test('fromMap applique les défauts et borne les valeurs', () {
    final stock = DiaperStockDto.fromMap({
      'count': 99999,
      'countedAt': Timestamp.fromDate(countedAt),
      'lastPackSize': 0,
    })!;
    expect(stock.count, 9999);
    expect(stock.alertThreshold, 10);
    expect(stock.lastPackSize, 1);
  });
}
```

`test/features/diapers/data/firestore_diaper_stock_repository_test.dart` :

```dart
import 'package:colette/features/diapers/data/repositories/firestore_diaper_stock_repository.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const code = 'ABCDEFGH';
  final stock = DiaperStock(count: 44, countedAt: DateTime(2026, 9, 20, 10));

  test('watchStock émet null tant que rien n\'est écrit', () async {
    final repo = FirestoreDiaperStockRepository(FakeFirebaseFirestore());
    expect(await repo.watchStock(code).first, isNull);
  });

  test('saveStock puis watchStock renvoie le stock', () async {
    final repo = FirestoreDiaperStockRepository(FakeFirebaseFirestore());
    await repo.saveStock(code, stock);
    expect(await repo.watchStock(code).first, stock);
  });

  test('saveStock fusionne sans effacer les autres champs du foyer', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('households').doc(code).set({
      'baby': {'name': 'Colette'},
    });
    final repo = FirestoreDiaperStockRepository(db);
    await repo.saveStock(code, stock);
    final data = (await db.collection('households').doc(code).get()).data()!;
    expect((data['baby'] as Map)['name'], 'Colette');
    expect((data['diaperStock'] as Map)['count'], 44);
  });
}
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run: `flutter test test/features/diapers/data`
Expected: FAIL, imports introuvables.

- [ ] **Step 3 : Implémenter interface, DTO et repository**

`lib/features/diapers/domain/repositories/diaper_stock_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:fpdart/fpdart.dart';

/// Stock de couches du foyer.
abstract interface class DiaperStockRepository {
  /// `null` tant que le stock n'a jamais été renseigné.
  Stream<DiaperStock?> watchStock(String householdCode);

  Future<Either<Failure, void>> saveStock(
    String householdCode,
    DiaperStock stock,
  );
}
```

`lib/features/diapers/data/dtos/diaper_stock_dto.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';

/// Conversion `DiaperStock` ↔ champ `diaperStock` du document foyer.
abstract final class DiaperStockDto {
  static Map<String, dynamic> toMap(DiaperStock stock) => {
    'count': stock.count,
    'countedAt': Timestamp.fromDate(stock.countedAt),
    'alertThreshold': stock.alertThreshold,
    'lastPackSize': stock.lastPackSize,
  };

  static int _readInt(
    Map<String, dynamic> map,
    String key,
    int fallback, {
    required int min,
    required int max,
  }) => ((map[key] as num?)?.toInt() ?? fallback).clamp(min, max);

  /// `null` sans `countedAt` valide : stock non renseigné. Valeurs bornées.
  static DiaperStock? fromMap(Map<String, dynamic> map) {
    final countedAt = map['countedAt'];
    if (countedAt is! Timestamp) return null;
    return DiaperStock(
      count: _readInt(map, 'count', 0, min: 0, max: 9999),
      countedAt: countedAt.toDate(),
      alertThreshold: _readInt(map, 'alertThreshold', 10, min: 0, max: 999),
      lastPackSize: _readInt(map, 'lastPackSize', 44, min: 1, max: 999),
    );
  }
}
```

`lib/features/diapers/data/repositories/firestore_diaper_stock_repository.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/diapers/data/dtos/diaper_stock_dto.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Stock dans `households/{code}.diaperStock`.
class FirestoreDiaperStockRepository implements DiaperStockRepository {
  FirestoreDiaperStockRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _household(String code) =>
      _db.collection(FirestorePaths.households).doc(code);

  @override
  Stream<DiaperStock?> watchStock(String householdCode) =>
      _household(householdCode).snapshots().map((snap) {
        final data = snap.data()?['diaperStock'] as Map<String, dynamic>?;
        return data == null ? null : DiaperStockDto.fromMap(data);
      });

  @override
  Future<Either<Failure, void>> saveStock(
    String householdCode,
    DiaperStock stock,
  ) => guard(
    () => _household(householdCode).set({
      'diaperStock': DiaperStockDto.toMap(stock),
    }, SetOptions(merge: true)),
  );
}
```

- [ ] **Step 4 : Vérifier**

Run: `flutter test test/features/diapers/data`
Expected: PASS, 7 tests.

- [ ] **Step 5 : Commit**

```bash
git add lib/features/diapers/domain/repositories lib/features/diapers/data test/features/diapers/data
git commit -m "feat: repository Firestore du stock de couches"
```

---

### Task 3 : Events — comptage des changes depuis une date

**Files:**
- Modify: `lib/features/events/domain/repositories/events_repository.dart`
- Modify: `lib/features/events/data/repositories/firestore_events_repository.dart`
- Modify: `lib/features/events/presentation/providers/events_providers.dart`
- Modify: `firestore.indexes.json`
- Test: `test/features/events/data/firestore_events_repository_test.dart`

Les tests existants utilisent des `Mock` mocktail pour `EventsRepository` : ajouter une méthode à l'interface ne les casse pas.

- [ ] **Step 1 : Écrire le test rouge**

À la fin de `main()` dans `test/features/events/data/firestore_events_repository_test.dart` :

```dart
  test('watchDiaperChangeCountSince ne compte que les changes à partir de from', () async {
    final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
    final from = day.add(const Duration(hours: 10));
    await repo.save(
      code,
      makeEvent(
        id: 'avant',
        startAt: day.add(const Duration(hours: 8)),
        diaperChange: true,
      ),
    );
    await repo.save(
      code,
      makeEvent(id: 'pile', startAt: from, diaperChange: true),
    );
    await repo.save(
      code,
      makeEvent(
        id: 'apres',
        startAt: day.add(const Duration(hours: 14)),
        diaperChange: true,
      ),
    );
    await repo.save(
      code,
      makeEvent(
        id: 'pipi',
        startAt: day.add(const Duration(hours: 15)),
        pee: true,
      ),
    );
    expect(await repo.watchDiaperChangeCountSince(code, from: from).first, 2);
  });
```

- [ ] **Step 2 : Vérifier qu'il échoue**

Run: `flutter test test/features/events/data/firestore_events_repository_test.dart`
Expected: FAIL, `watchDiaperChangeCountSince` n'est pas défini.

- [ ] **Step 3 : Ajouter la méthode à l'interface et à l'implémentation**

Dans `lib/features/events/domain/repositories/events_repository.dart`, après `watchLatestBottle` :

```dart
  /// Nombre d'événements « change » dont `startAt` est ≥ [from].
  Stream<int> watchDiaperChangeCountSince(
    String householdCode, {
    required DateTime from,
  });
```

Dans `lib/features/events/data/repositories/firestore_events_repository.dart`, après `watchLatestBottle` :

```dart
  @override
  Stream<int> watchDiaperChangeCountSince(
    String householdCode, {
    required DateTime from,
  }) =>
      _events(householdCode)
          .where('diaperChange', isEqualTo: true)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .snapshots()
          .map((snap) => snap.docs.length);
```

- [ ] **Step 4 : Vérifier**

Run: `flutter test test/features/events/data/firestore_events_repository_test.dart`
Expected: PASS.

- [ ] **Step 5 : Ajouter le provider public et l'index**

Dans `lib/features/events/presentation/providers/events_providers.dart`, après `latestBottle` :

```dart
/// Nombre de changes enregistrés depuis [from] ; `0` sans foyer.
@riverpod
Stream<int> diaperChangesSince(Ref ref, DateTime from) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(0);
  return ref
      .watch(eventsRepositoryProvider)
      .watchDiaperChangeCountSince(code, from: from);
}
```

Dans `firestore.indexes.json`, ajouter dans le tableau `indexes` après l'index `hasBottle` :

```json
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "diaperChange", "order": "ASCENDING" },
        { "fieldPath": "startAt", "order": "ASCENDING" }
      ]
    }
```

- [ ] **Step 6 : Générer et vérifier**

Run: `dart run build_runner build -d && dart analyze && flutter test test/features/events`
Expected: aucune erreur, tests verts.

- [ ] **Step 7 : Commit**

```bash
git add lib/features/events/domain/repositories/events_repository.dart lib/features/events/data/repositories/firestore_events_repository.dart lib/features/events/presentation/providers/events_providers.dart lib/features/events/presentation/providers/events_providers.g.dart firestore.indexes.json test/features/events/data/firestore_events_repository_test.dart
git commit -m "feat: comptage des changes depuis une date (events)"
```

---

### Task 4 : Raison de validation et chaînes

**Files:**
- Modify: `lib/core/result/failure.dart`
- Modify: `lib/core/ui/failure_message.dart`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/core/ui/failure_message_test.dart` (existant, couvre déjà toutes les raisons)

- [ ] **Step 1 : Ajouter la raison**

Dans `lib/core/result/failure.dart`, ajouter à la fin de `enum ValidationReason` :

```dart
  invalidDiaperCount,
```

- [ ] **Step 2 : Vérifier que le test existant échoue**

Run: `dart analyze`
Expected: erreur `non_exhaustive_switch` dans `failure_message.dart` (le switch sur `reason` ne couvre plus toutes les valeurs).

- [ ] **Step 3 : Ajouter le message et toutes les chaînes de la feature**

Dans `lib/core/ui/failure_message.dart`, dans le `switch (reason)`, après la ligne `notificationsDenied` :

```dart
    ValidationReason.invalidDiaperCount => s.errorInvalidDiaperCount,
```

Dans `lib/l10n/app_fr.arb`, après la ligne `"errorInvalidWeight": …` :

```json
  "errorInvalidDiaperCount": "Le nombre de couches doit être entre 0 et 9 999.",
```

Et avant la ligne `"settingsNotificationsSection": …` :

```json
  "settingsDiapersSection": "Couches",
  "diapersRemaining": "{count, plural, =0{Plus de couches} =1{Il reste 1 couche} other{Il reste {count} couches}}",
  "@diapersRemaining": { "placeholders": { "count": { "type": "int" } } },
  "diapersNotSet": "Stock non renseigné",
  "diapersRecount": "Recompter",
  "diapersAddPack": "+ paquet",
  "diapersAlertThreshold": "Alerte sous N couches",
  "diapersRecountTitle": "Couches en stock",
  "diapersAddPackTitle": "Taille du paquet",
  "diapersFieldCount": "Nombre de couches",
  "diapersAlertLow": "{count, plural, =0{Plus de couches !} =1{Plus que 1 couche} other{Plus que {count} couches}}",
  "@diapersAlertLow": { "placeholders": { "count": { "type": "int" } } },
```

- [ ] **Step 4 : Régénérer les localisations et vérifier**

Run: `flutter gen-l10n && dart analyze && flutter test test/core/ui/failure_message_test.dart`
Expected: aucune erreur, test vert (chaque raison a un message distinct non vide).

- [ ] **Step 5 : Commit**

```bash
git add lib/core/result/failure.dart lib/core/ui/failure_message.dart lib/l10n/app_fr.arb
git commit -m "feat: chaînes et raison de validation du stock de couches"
```

(`lib/l10n/generated/` n'est pas versionné : `generate: true` dans `pubspec.yaml` le régénère à chaque build et test.)

---

### Task 5 : Providers et contrôleur

**Files:**
- Create: `lib/features/diapers/presentation/providers/diaper_stock_providers.dart`
- Create: `lib/features/diapers/presentation/providers/diaper_stock_controller.dart`
- Test: `test/features/diapers/presentation/diaper_stock_providers_test.dart`
- Test: `test/features/diapers/presentation/diaper_stock_controller_test.dart`

- [ ] **Step 1 : Écrire les tests rouges**

`test/features/diapers/presentation/diaper_stock_providers_test.dart` :

```dart
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockDiaperStockRepository extends Mock implements DiaperStockRepository {}

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final countedAt = DateTime(2026, 9, 20, 10);

  ProviderContainer containerWith({
    required DiaperStock? stock,
    required int changes,
  }) {
    final stockRepo = MockDiaperStockRepository();
    final eventsRepo = MockEventsRepository();
    when(() => stockRepo.watchStock(any()))
        .thenAnswer((_) => Stream.value(stock));
    when(
      () => eventsRepo.watchDiaperChangeCountSince(any(), from: any(named: 'from')),
    ).thenAnswer((_) => Stream.value(changes));
    final container = ProviderContainer(
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(stockRepo),
        eventsRepositoryProvider.overrideWithValue(eventsRepo),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('diaperStockStatus est null sans stock renseigné', () async {
    final container = containerWith(stock: null, changes: 3);
    final sub = container.listen(diaperStockStatusProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(diaperStockProvider.future);
    expect(container.read(diaperStockStatusProvider), isNull);
  });

  test('diaperStockStatus combine le stock et les changes depuis countedAt', () async {
    final container = containerWith(
      stock: DiaperStock(count: 12, countedAt: countedAt),
      changes: 3,
    );
    final sub = container.listen(diaperStockStatusProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(diaperStockProvider.future);
    await container.read(diaperChangesSinceProvider(countedAt).future);
    expect(
      container.read(diaperStockStatusProvider),
      const DiaperStockStatus(remaining: 9, isLow: true),
    );
  });
}
```

`test/features/diapers/presentation/diaper_stock_controller_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_controller.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockDiaperStockRepository extends Mock implements DiaperStockRepository {}

void main() {
  late MockDiaperStockRepository repo;
  late ProviderContainer container;
  final now = DateTime(2026, 9, 22, 15);
  final countedAt = DateTime(2026, 9, 20, 10);
  final stock = DiaperStock(
    count: 44,
    countedAt: countedAt,
    alertThreshold: 12,
    lastPackSize: 30,
  );

  setUpAll(() => registerFallbackValue(stock));

  setUp(() {
    repo = MockDiaperStockRepository();
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) async => right(null));
    container = ProviderContainer(
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  DiaperStockController controller() =>
      container.read(diaperStockControllerProvider.notifier);

  DiaperStock captured() =>
      verify(() => repo.saveStock('ABCDEFGH', captureAny())).captured.single
          as DiaperStock;

  test('recount écrit count et countedAt = now', () async {
    expect(await controller().recount(stock, 20), isTrue);
    final saved = captured();
    expect(saved.count, 20);
    expect(saved.countedAt, now);
    expect(saved.alertThreshold, 12);
  });

  test('recount sans stock crée le stock avec les défauts', () async {
    expect(await controller().recount(null, 20), isTrue);
    final saved = captured();
    expect(saved, DiaperStock(count: 20, countedAt: now));
  });

  test('addPack écrit restant + taille et mémorise la taille', () async {
    expect(await controller().addPack(stock, remaining: 7, size: 50), isTrue);
    final saved = captured();
    expect(saved.count, 57);
    expect(saved.countedAt, now);
    expect(saved.lastPackSize, 50);
  });

  test('addPack sans stock part d\'un restant à 0', () async {
    expect(await controller().addPack(null, remaining: 0, size: 44), isTrue);
    expect(captured().count, 44);
  });

  test('setThreshold conserve count et countedAt', () async {
    expect(await controller().setThreshold(stock, 5), isTrue);
    final saved = captured();
    expect(saved.alertThreshold, 5);
    expect(saved.count, 44);
    expect(saved.countedAt, countedAt);
  });

  test('recount refuse une valeur hors bornes', () async {
    expect(await controller().recount(stock, 10000), isFalse);
    expect(
      container.read(diaperStockControllerProvider).error,
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.invalidDiaperCount,
      ),
    );
    verifyNever(() => repo.saveStock(any(), any()));
  });

  test('addPack refuse une taille nulle', () async {
    expect(await controller().addPack(stock, remaining: 7, size: 0), isFalse);
    verifyNever(() => repo.saveStock(any(), any()));
  });

  test('un échec du repository est exposé dans l\'état', () async {
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    expect(await controller().recount(stock, 20), isFalse);
    expect(
      container.read(diaperStockControllerProvider).error,
      isA<NetworkFailure>(),
    );
  });
}
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run: `flutter test test/features/diapers/presentation`
Expected: FAIL, imports introuvables.

- [ ] **Step 3 : Implémenter les providers**

`lib/features/diapers/presentation/providers/diaper_stock_providers.dart` :

```dart
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/diapers/data/repositories/firestore_diaper_stock_repository.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/domain/use_cases/compute_diaper_stock_status.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diaper_stock_providers.g.dart';

/// Sans état : `keepAlive` comme les autres repositories.
@Riverpod(keepAlive: true)
DiaperStockRepository diaperStockRepository(Ref ref) =>
    FirestoreDiaperStockRepository(ref.watch(firestoreProvider));

/// Stock du foyer courant ; `null` sans foyer ou tant qu'il n'est pas renseigné.
@riverpod
Stream<DiaperStock?> diaperStock(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(diaperStockRepositoryProvider).watchStock(code);
}

/// Restant et alerte ; `null` tant que le stock n'est pas renseigné.
@riverpod
DiaperStockStatus? diaperStockStatus(Ref ref) {
  final stock = ref.watch(diaperStockProvider).value;
  if (stock == null) return null;
  final changes =
      ref.watch(diaperChangesSinceProvider(stock.countedAt)).value ?? 0;
  return const ComputeDiaperStockStatus()(
    stock: stock,
    changesSinceCount: changes,
  );
}
```

`lib/features/diapers/presentation/providers/diaper_stock_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diaper_stock_controller.g.dart';

/// Recomptage, ajout de paquet et seuil d'alerte. L'état porte l'échec éventuel.
/// Reçoit le stock courant en paramètre (`null` s'il n'est pas encore renseigné).
@riverpod
class DiaperStockController extends _$DiaperStockController {
  static const maxCount = 9999;
  static const maxPackSize = 999;
  static const maxThreshold = 999;

  @override
  FutureOr<void> build() {}

  /// Pose [count] comme nouveau stock à l'instant présent.
  Future<bool> recount(DiaperStock? current, int count) {
    if (count < 0 || count > maxCount) return _reject();
    final now = ref.read(clockProvider).now();
    final base = current ?? DiaperStock(count: 0, countedAt: now);
    return _save(base.recount(count, now: now));
  }

  /// Ajoute un paquet de [size] couches au [remaining] courant.
  Future<bool> addPack(
    DiaperStock? current, {
    required int remaining,
    required int size,
  }) {
    if (size < 1 || size > maxPackSize) return _reject();
    if (remaining + size > maxCount) return _reject();
    final now = ref.read(clockProvider).now();
    final base = current ?? DiaperStock(count: 0, countedAt: now);
    return _save(base.addPack(size, remaining: remaining, now: now));
  }

  Future<bool> setThreshold(DiaperStock current, int threshold) {
    if (threshold < 0 || threshold > maxThreshold) return _reject();
    return _save(current.copyWith(alertThreshold: threshold));
  }

  Future<bool> _reject() async {
    state = AsyncError(
      const ValidationFailure(ValidationReason.invalidDiaperCount),
      StackTrace.current,
    );
    return false;
  }

  Future<bool> _save(DiaperStock stock) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await ref
        .read(diaperStockRepositoryProvider)
        .saveStock(code, stock);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
```

- [ ] **Step 4 : Générer et vérifier**

Run: `dart run build_runner build -d && dart analyze && flutter test test/features/diapers`
Expected: aucune erreur, tous les tests verts (10 nouveaux).

- [ ] **Step 5 : Commit**

```bash
git add lib/features/diapers/presentation/providers test/features/diapers/presentation
git commit -m "feat: providers et contrôleur du stock de couches"
```

---

### Task 6 : Bottom sheet « Recompter » / « + paquet »

**Files:**
- Create: `lib/features/diapers/presentation/widgets/diaper_stock_sheet.dart`
- Test: `test/features/diapers/presentation/diaper_stock_sheet_test.dart`

- [ ] **Step 1 : Écrire les tests rouges**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockDiaperStockRepository extends Mock implements DiaperStockRepository {}

void main() {
  final now = DateTime(2026, 9, 22, 15);
  final stock = DiaperStock(
    count: 44,
    countedAt: DateTime(2026, 9, 20, 10),
    lastPackSize: 30,
  );

  setUpAll(() => registerFallbackValue(stock));

  Future<MockDiaperStockRepository> pumpSheet(
    WidgetTester tester, {
    required DiaperStockSheetMode mode,
    required DiaperStock? current,
    required int remaining,
  }) async {
    final repo = MockDiaperStockRepository();
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDiaperStockSheet(
              context,
              mode: mode,
              current: current,
              remaining: remaining,
            ),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('recompter enregistre la valeur saisie', (tester) async {
    final repo = await pumpSheet(
      tester,
      mode: DiaperStockSheetMode.recount,
      current: stock,
      remaining: 40,
    );
    expect(find.text('Couches en stock'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveStock('ABCDEFGH', captureAny())).captured.single
            as DiaperStock;
    expect(saved.count, 25);
    expect(saved.countedAt, now);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('+ paquet est prérempli et ajoute au restant', (tester) async {
    final repo = await pumpSheet(
      tester,
      mode: DiaperStockSheetMode.addPack,
      current: stock,
      remaining: 7,
    );
    expect(find.text('Taille du paquet'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '30',
    );
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveStock('ABCDEFGH', captureAny())).captured.single
            as DiaperStock;
    expect(saved.count, 37);
    expect(saved.lastPackSize, 30);
  });

  testWidgets('une valeur invalide laisse la feuille ouverte', (tester) async {
    final repo = await pumpSheet(
      tester,
      mode: DiaperStockSheetMode.recount,
      current: null,
      remaining: 0,
    );
    await tester.enterText(find.byType(TextField), '-1');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.saveStock(any(), any()));
    expect(find.byType(TextField), findsOneWidget);
  });
}
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run: `flutter test test/features/diapers/presentation/diaper_stock_sheet_test.dart`
Expected: FAIL, import introuvable.

- [ ] **Step 3 : Implémenter la feuille**

`lib/features/diapers/presentation/widgets/diaper_stock_sheet.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ce que la feuille enregistre : un nouveau comptage ou un paquet ajouté.
enum DiaperStockSheetMode { recount, addPack }

/// Ouvre la saisie du stock. [current] est `null` tant que le stock n'est pas renseigné.
Future<void> showDiaperStockSheet(
  BuildContext context, {
  required DiaperStockSheetMode mode,
  required DiaperStock? current,
  required int remaining,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      DiaperStockSheet(mode: mode, current: current, remaining: remaining),
);

/// Un champ numérique et un bouton, en mode recomptage ou ajout de paquet.
class DiaperStockSheet extends ConsumerStatefulWidget {
  const DiaperStockSheet({
    super.key,
    required this.mode,
    required this.current,
    required this.remaining,
  });

  final DiaperStockSheetMode mode;
  final DiaperStock? current;
  final int remaining;

  @override
  ConsumerState<DiaperStockSheet> createState() => _DiaperStockSheetState();
}

class _DiaperStockSheetState extends ConsumerState<DiaperStockSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: switch (widget.mode) {
      DiaperStockSheetMode.recount => '',
      DiaperStockSheetMode.addPack => '${widget.current?.lastPackSize ?? 44}',
    },
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = int.tryParse(_controller.text.trim()) ?? -1;
    final controller = ref.read(diaperStockControllerProvider.notifier);
    final ok = switch (widget.mode) {
      DiaperStockSheetMode.recount => await controller.recount(
        widget.current,
        value,
      ),
      DiaperStockSheetMode.addPack => await controller.addPack(
        widget.current,
        remaining: widget.remaining,
        size: value,
      ),
    };
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de _save.
    ref.watch(diaperStockControllerProvider);
    final s = S.of(context);
    final (title, action) = switch (widget.mode) {
      DiaperStockSheetMode.recount => (s.diapersRecountTitle, s.actionSave),
      DiaperStockSheetMode.addPack => (s.diapersAddPackTitle, s.actionAdd),
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(title, style: Theme.of(context).coletteTextStyles.heading2),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: s.diapersFieldCount),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          AppSpacing.lg.verticalSpace,
          FilledButton(onPressed: _save, child: Text(action)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4 : Vérifier**

Run: `dart analyze && flutter test test/features/diapers/presentation/diaper_stock_sheet_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5 : Commit**

```bash
git add lib/features/diapers/presentation/widgets/diaper_stock_sheet.dart test/features/diapers/presentation/diaper_stock_sheet_test.dart
git commit -m "feat: feuille de saisie du stock de couches"
```

---

### Task 7 : Section « Couches » dans les Réglages

**Files:**
- Create: `lib/features/diapers/presentation/widgets/diaper_stock_section.dart`
- Modify: `lib/features/baby/presentation/pages/settings_page.dart`
- Test: `test/features/diapers/presentation/diaper_stock_section_test.dart`
- Test: `test/features/baby/presentation/settings_page_test.dart`

- [ ] **Step 1 : Écrire les tests rouges**

`test/features/diapers/presentation/diaper_stock_section_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_section.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockDiaperStockRepository extends Mock implements DiaperStockRepository {}

void main() {
  final countedAt = DateTime(2026, 9, 20, 10);
  final stock = DiaperStock(count: 44, countedAt: countedAt, alertThreshold: 10);

  setUpAll(() => registerFallbackValue(stock));

  Future<MockDiaperStockRepository> pumpSection(
    WidgetTester tester, {
    required DiaperStock? current,
    required int changes,
  }) async {
    final repo = MockDiaperStockRepository();
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: DiaperStockSection())),
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(repo),
        diaperStockProvider.overrideWith((ref) => Stream.value(current)),
        diaperChangesSinceProvider.overrideWith(
          (ref, from) => Stream.value(changes),
        ),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 22, 15))),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    return repo;
  }

  testWidgets('affiche le restant et le stepper de seuil', (tester) async {
    await pumpSection(tester, current: stock, changes: 4);
    expect(find.text('Il reste 40 couches'), findsOneWidget);
    expect(find.text('Recompter'), findsOneWidget);
    expect(find.text('+ paquet'), findsOneWidget);
    expect(find.byType(IntStepperRow), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('sans stock : « Stock non renseigné » et pas de stepper', (
    tester,
  ) async {
    await pumpSection(tester, current: null, changes: 0);
    expect(find.text('Stock non renseigné'), findsOneWidget);
    expect(find.byType(IntStepperRow), findsNothing);
    expect(find.text('Recompter'), findsOneWidget);
  });

  testWidgets('le stepper enregistre le seuil', (tester) async {
    final repo = await pumpSection(tester, current: stock, changes: 0);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveStock('ABCDEFGH', captureAny())).captured.single
            as DiaperStock;
    expect(saved.alertThreshold, 9);
    expect(saved.count, 44);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('« Recompter » ouvre la feuille', (tester) async {
    await pumpSection(tester, current: stock, changes: 0);
    await tester.tap(find.text('Recompter'));
    await tester.pumpAndSettle();
    expect(find.text('Couches en stock'), findsOneWidget);
  });
}
```

Dans `test/features/baby/presentation/settings_page_test.dart`, ajouter l'import :

```dart
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
```

ajouter dans `overrides`, après `currentDeviceProvider.overrideWith(...)` :

```dart
        diaperStockProvider.overrideWith((ref) => Stream.value(null)),
```

et après `expect(find.text('Soins attendus'), findsOneWidget);` :

```dart
    expect(find.text('Couches'), findsOneWidget);
    expect(find.text('Stock non renseigné'), findsOneWidget);
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run: `flutter test test/features/diapers/presentation/diaper_stock_section_test.dart test/features/baby/presentation/settings_page_test.dart`
Expected: FAIL (import introuvable ; page Réglages sans « Couches »).

- [ ] **Step 3 : Implémenter la section**

`lib/features/diapers/presentation/widgets/diaper_stock_section.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_controller.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stock restant, recomptage, ajout de paquet et seuil d'alerte.
class DiaperStockSection extends ConsumerWidget {
  const DiaperStockSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final stock = ref.watch(diaperStockProvider).value;
    final status = ref.watch(diaperStockStatusProvider);
    final remaining = status?.remaining ?? 0;
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.sm.all,
            child: Text(
              status == null
                  ? s.diapersNotSet
                  : s.diapersRemaining(status.remaining),
              style: status == null
                  ? styles.body.copyWith(
                      color: context.appColor(AppColors.textSecondary),
                    )
                  : styles.bodyMedium,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => showDiaperStockSheet(
                    context,
                    mode: DiaperStockSheetMode.recount,
                    current: stock,
                    remaining: remaining,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(s.diapersRecount),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => showDiaperStockSheet(
                    context,
                    mode: DiaperStockSheetMode.addPack,
                    current: stock,
                    remaining: remaining,
                  ),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(s.diapersAddPack),
                ),
              ),
            ],
          ),
          if (stock != null) _ThresholdStepper(stock: stock),
        ],
      ),
    );
  }
}

/// Stepper du seuil avec copie locale optimiste : des taps rapides s'enchaînent.
class _ThresholdStepper extends ConsumerStatefulWidget {
  const _ThresholdStepper({required this.stock});

  final DiaperStock stock;

  @override
  ConsumerState<_ThresholdStepper> createState() => _ThresholdStepperState();
}

class _ThresholdStepperState extends ConsumerState<_ThresholdStepper> {
  late int _threshold = widget.stock.alertThreshold;

  @override
  void didUpdateWidget(covariant _ThresholdStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.stock.alertThreshold;
    final writing = ref.read(diaperStockControllerProvider).isLoading;
    if (incoming != oldWidget.stock.alertThreshold && !writing) {
      _threshold = incoming;
    }
  }

  void _update(int next) {
    setState(() => _threshold = next);
    ref
        .read(diaperStockControllerProvider.notifier)
        .setThreshold(widget.stock, next);
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de setThreshold.
    ref.watch(diaperStockControllerProvider);
    return IntStepperRow(
      label: S.of(context).diapersAlertThreshold,
      value: _threshold,
      min: 0,
      max: 30,
      onChanged: _update,
    );
  }
}
```

Dans `lib/features/baby/presentation/pages/settings_page.dart` :

Ajouter les imports (ordre alphabétique) :

```dart
import 'package:colette/features/diapers/presentation/providers/diaper_stock_controller.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_section.dart';
```

Ajouter, après le `ref.listen(notificationSettingsControllerProvider, …)` :

```dart
    ref.listen(diaperStockControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
```

Et dans la `ListView`, juste après `CareSettingsSection(profile: profile),` mais **hors** du `if (profile != null)` (le stock ne dépend pas du profil), c'est-à-dire après le `else … CircularProgressIndicator()` et avant `if (device != null)` :

```dart
          SectionHeader(title: s.settingsDiapersSection),
          const DiaperStockSection(),
```

- [ ] **Step 4 : Vérifier**

Run: `dart analyze && flutter test test/features/diapers test/features/baby/presentation/settings_page_test.dart`
Expected: PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/features/diapers/presentation/widgets/diaper_stock_section.dart lib/features/baby/presentation/pages/settings_page.dart test/features/diapers/presentation/diaper_stock_section_test.dart test/features/baby/presentation/settings_page_test.dart
git commit -m "feat: section Couches dans les Réglages"
```

---

### Task 8 : Carte d'alerte sur l'accueil

**Files:**
- Create: `lib/features/diapers/presentation/widgets/diaper_stock_alert_card.dart`
- Modify: `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Test: `test/features/diapers/presentation/diaper_stock_alert_card_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_page_test.dart`

Couleurs : fond `AppColors.categoryDiaper`, texte `AppColors.onPrimary`. Cette paire est déjà validée par `app_colors_contrast_test.dart` en clair et en sombre ; aucun token à ajouter.

- [ ] **Step 1 : Écrire les tests rouges**

`test/features/diapers/presentation/diaper_stock_alert_card_test.dart` :

```dart
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_alert_card.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, DiaperStockStatus? status) =>
      pumpApp(
        tester,
        const Scaffold(body: DiaperStockAlertCard()),
        overrides: [diaperStockStatusProvider.overrideWithValue(status)],
      );

  testWidgets('rien sans stock renseigné', (tester) async {
    await pumpCard(tester, null);
    expect(find.byType(ColetteCardSurface), findsNothing);
    expect(find.textContaining('couche'), findsNothing);
  });

  testWidgets('rien au-dessus du seuil', (tester) async {
    await pumpCard(tester, const DiaperStockStatus(remaining: 20, isLow: false));
    expect(find.byType(ColetteCardSurface), findsNothing);
  });

  testWidgets('alerte sous le seuil', (tester) async {
    await pumpCard(tester, const DiaperStockStatus(remaining: 7, isLow: true));
    expect(find.text('Plus que 7 couches'), findsOneWidget);
  });

  testWidgets('texte à zéro', (tester) async {
    await pumpCard(tester, const DiaperStockStatus(remaining: 0, isLow: true));
    expect(find.text('Plus de couches !'), findsOneWidget);
  });
}
```

Dans `test/features/dashboard/presentation/dashboard_page_test.dart` :

Ajouter les imports :

```dart
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
```

Remplacer la signature de `overridesFor` et ajouter la surcharge à la fin de sa liste :

```dart
  List<Override> overridesFor(
    MockEventsRepository repo, {
    DiaperStockStatus? diaperStatus,
  }) => [
    // … surcharges existantes inchangées …
    diaperStockStatusProvider.overrideWithValue(diaperStatus),
  ];
```

Les deux tests existants appellent `overridesFor(repo)` sans argument : ils continuent de tourner sans stock renseigné. Ajouter un test à la fin de `main()` :

```dart
  testWidgets('affiche l\'alerte de stock de couches sous le seuil', (
    tester,
  ) async {
    final repo = MockEventsRepository();
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(
        repo,
        diaperStatus: const DiaperStockStatus(remaining: 4, isLow: true),
      ),
    );
    expect(find.text('Plus que 4 couches'), findsOneWidget);
  });
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run: `flutter test test/features/diapers/presentation/diaper_stock_alert_card_test.dart test/features/dashboard/presentation/dashboard_page_test.dart`
Expected: FAIL (import introuvable ; pas d'alerte sur l'accueil).

- [ ] **Step 3 : Implémenter la carte**

`lib/features/diapers/presentation/widgets/diaper_stock_alert_card.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Plus que N couches », visible uniquement sous le seuil d'alerte.
/// Tap : ouvre l'onglet Réglages.
class DiaperStockAlertCard extends ConsumerWidget {
  const DiaperStockAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(diaperStockStatusProvider);
    if (status == null || !status.isLow) return const SizedBox.shrink();
    final color = context.appColor(AppColors.onPrimary);
    return Padding(
      padding: AppSpacing.md.bottom,
      child: ColetteCardSurface(
        backgroundColor: AppColors.categoryDiaper,
        borderColor: AppColors.categoryDiaper,
        onTap: () => GoRouter.maybeOf(context)?.go(AppRoutes.settings),
        child: Row(
          children: [
            Icon(Icons.baby_changing_station, color: color),
            AppSpacing.sm.horizontalSpace,
            Expanded(
              child: Text(
                S.of(context).diapersAlertLow(status.remaining),
                style: Theme.of(context).coletteTextStyles.bodyMedium
                    .copyWith(color: color),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
```

`GoRouter.maybeOf` évite une exception dans les tests montés sans routeur (`pumpApp` utilise `MaterialApp.home`).

Dans `lib/features/dashboard/presentation/pages/dashboard_page.dart` :

Ajouter l'import :

```dart
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_alert_card.dart';
```

Dans la `ListView`, remplacer :

```dart
            const DashboardHeader(),
            AppSpacing.md.verticalSpace,
            const NextBottleCard(),
```

par :

```dart
            const DashboardHeader(),
            AppSpacing.md.verticalSpace,
            const DiaperStockAlertCard(),
            const NextBottleCard(),
```

(La carte porte son propre espacement bas, et rend `SizedBox.shrink()` quand il n'y a rien à dire : la mise en page reste identique hors alerte.)

- [ ] **Step 4 : Vérifier**

Run: `dart analyze && flutter test test/features/diapers test/features/dashboard`
Expected: PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/features/diapers/presentation/widgets/diaper_stock_alert_card.dart lib/features/dashboard/presentation/pages/dashboard_page.dart test/features/diapers/presentation/diaper_stock_alert_card_test.dart test/features/dashboard/presentation/dashboard_page_test.dart
git commit -m "feat: alerte de stock de couches sur l'accueil"
```

---

### Task 9 : Documentation et vérification finale

**Files:**
- Modify: `docs/superpowers/specs/2026-09-21-colette-v1-design.md`
- Modify: `docs/superpowers/specs/2026-09-22-diaper-stock-design.md`

- [ ] **Step 1 : Mettre à jour la spec v1**

Section 5 (« Données Firestore »), dans le bloc `households/{code}`, après le bloc `feedingPlan:` :

```
  diaperStock:                        stock de couches, renseigné depuis les Réglages
    count: number                     couches comptées à countedAt
    countedAt: Timestamp              restant = count − changes dont startAt ≥ countedAt
    alertThreshold: 10                0 = alerte désactivée
    lastPackSize: 44
```

Section 6.2, dans la liste « Contenu, de haut en bas », insérer après l'item 1 (en-tête) :

```
2. Carte d'alerte « Plus que N couches », uniquement si le stock restant est strictement inférieur au seuil (voir `2026-09-22-diaper-stock-design.md`). Tap : ouvre les Réglages.
```

et renuméroter les items suivants (3, 4, 5).

Section 6.6, dans la liste des sections, après « Soins attendus » :

```
- Couches : stock restant, « Recompter », « + paquet », seuil d'alerte (0 à 30, 0 = désactivé).
```

- [ ] **Step 2 : Aligner la spec du stock sur les signatures réelles**

Dans `docs/superpowers/specs/2026-09-22-diaper-stock-design.md`, section 5.4, remplacer les trois puces d'actions du contrôleur par :

```
- `recount(DiaperStock? current, int count)` : `current` (ou `DiaperStock` neuf si `null`) → `recount`, puis `saveStock`.
- `addPack(DiaperStock? current, {required int remaining, required int size})` : `current` (ou neuf) → `addPack`, puis `saveStock`.
- `setThreshold(DiaperStock current, int threshold)` : `copyWith(alertThreshold:)`, puis `saveStock`. Le stepper n'est affiché que si le stock est renseigné.

Le stock courant et le restant sont passés par le widget appelant, comme `BabySettingsController.updateCareSettings(profile, settings)`, plutôt que relus depuis un provider pendant l'`await`.
```

Et dans la section 5.4 « Widgets », puce de la carte : remplacer « `ColetteCardSurface` sur fond `AppColors.warning` » par « `ColetteCardSurface` sur fond `AppColors.categoryDiaper`, texte `AppColors.onPrimary` (paire déjà validée par le test de contraste) ».

Dans la section 5.5, supprimer la clé `diapersAlertEmpty` : le cas « Plus de couches » est porté par la forme `=0` des pluriels `diapersRemaining` et `diapersAlertLow`.

- [ ] **Step 3 : Vérification complète**

Run:

```bash
dart run build_runner build -d && dart format lib test && dart analyze && flutter test
```

Expected: `dart format` ne modifie rien (ou seulement des fichiers de cette feature, à inclure au commit), `dart analyze` : « No issues found! », `flutter test` : tous les tests verts.

- [ ] **Step 4 : Vérification manuelle sur simulateur iPhone**

Lancer l'app, puis :

1. Réglages → section « Couches » affiche « Stock non renseigné », sans stepper.
2. « Recompter » → 44 → « Il reste 44 couches », stepper à 10.
3. Aujourd'hui → ajouter un événement avec « Couche » coché → Réglages : « Il reste 43 couches ».
4. Journal → supprimer cet événement → « Il reste 44 couches ».
5. Réglages → « Recompter » → 5 → Aujourd'hui : carte « Plus que 5 couches » ; tap → Réglages.
6. Stepper de seuil à 0 → la carte disparaît.
7. Vérifier la carte et la section en thème sombre.

- [ ] **Step 5 : Commit**

```bash
git add docs/superpowers/specs/2026-09-21-colette-v1-design.md docs/superpowers/specs/2026-09-22-diaper-stock-design.md
git commit -m "docs: stock de couches dans la spec v1"
```
