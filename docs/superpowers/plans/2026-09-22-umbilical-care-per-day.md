# Nombre de soins du nombril par jour — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer l'interrupteur « Soin du nombril » par un nombre de soins attendus par jour (défaut 3, 0 = désactivé), côté app Flutter et côté Cloud Functions.

**Architecture:** Le champ `CareSettings.umbilicalCareEnabled: bool` devient `umbilicalCarePerDay: int`, traité comme Adrigyl, yeux et nez dans `ComputeDailyCareStatus` (Flutter) et `pendingCares` (fonctions). Le DTO Flutter et `withDefaults` des fonctions lisent l'ancien booléen en repli, aucune migration Firestore. Renseigner la date de chute du cordon met le compteur à 0, l'effacer le remet à 3.

**Tech Stack:** Flutter (freezed, Riverpod codegen, fpdart, mocktail), Cloud Functions TypeScript (vitest). Spec : `docs/superpowers/specs/2026-09-22-umbilical-care-per-day-design.md`.

**Arbre de travail :** le dépôt contient des modifications non commitées d'un autre chantier (mode d'apparence : `lib/app/colette_app.dart`, `settings_page.dart`, `theme_mode_*`, et quatre clés `theme*` ajoutées dans `lib/l10n/app_fr.arb`). Ne jamais faire `git add -A` ni `git add .` : stager uniquement les fichiers listés dans chaque tâche. Pour `app_fr.arb`, stager la seule ligne du nombril avec le patch indiqué en Tâche 1.

---

### Tâche 1 : App Flutter — entité, use case, DTO, contrôleur, formulaire, réglages

**Files:**
- Modify: `lib/features/baby/domain/entities/care_settings.dart`
- Modify: `lib/features/dashboard/domain/use_cases/compute_daily_care_status.dart:42`
- Modify: `lib/features/baby/data/dtos/baby_profile_dto.dart:5-34`
- Modify: `lib/features/baby/presentation/providers/baby_settings_controller.dart:32-41`
- Modify: `lib/features/events/presentation/widgets/event_form_sheet.dart:121-134`
- Modify: `lib/features/baby/presentation/widgets/care_settings_section.dart`
- Modify: `lib/l10n/app_fr.arb:110`
- Test: `test/features/dashboard/domain/compute_daily_care_status_test.dart`
- Test: `test/features/baby/data/baby_profile_dto_test.dart`
- Test: `test/features/baby/presentation/baby_settings_controller_test.dart`
- Test: `test/features/events/presentation/event_form_sheet_test.dart`
- Test: `test/features/baby/presentation/care_settings_section_test.dart`

Le renommage touche toutes les couches : les tests sont écrits d'abord (ils échouent à la compilation), puis l'implémentation est faite couche par couche, et l'ensemble est commité une fois vert.

- [ ] **Étape 1 : tests du domaine (rouge)**

Dans `test/features/dashboard/domain/compute_daily_care_status_test.dart`, remplacer le test `'nombril désactivé : pas de tâche nombril'` par les deux tests suivants :

```dart
  test('nombril à 0 : pas de tâche nombril', () {
    final tasks = compute(
      settings: const CareSettings(umbilicalCarePerDay: 0),
      todayEvents: const [],
      lastBath: null,
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.umbilicalCare), isFalse);
  });

  test('nombril 3 par jour par défaut : deux soins faits, reste à faire', () {
    final tasks = compute(
      settings: const CareSettings(),
      todayEvents: [
        makeEvent(id: 'u1', startAt: DateTime(2026, 9, 21, 8), umbilicalCare: true),
        makeEvent(id: 'u2', startAt: DateTime(2026, 9, 21, 12), umbilicalCare: true),
      ],
      lastBath: null,
      now: now,
    );
    final umbilical = tasks.firstWhere((t) => t.type == CareType.umbilicalCare);
    expect(umbilical.target, 3);
    expect(umbilical.done, 2);
    expect(umbilical.isDone, isFalse);
    expect(umbilical.lastDoneAt, DateTime(2026, 9, 21, 12));
  });
```

- [ ] **Étape 2 : tests du DTO (rouge)**

Ajouter à la fin de `main()` dans `test/features/baby/data/baby_profile_dto_test.dart` :

```dart
  test('CareSettingsDto.fromMap lit umbilicalCarePerDay borné', () {
    expect(
      CareSettingsDto.fromMap(const {'umbilicalCarePerDay': 2}).umbilicalCarePerDay,
      2,
    );
    expect(
      CareSettingsDto.fromMap(const {'umbilicalCarePerDay': 42}).umbilicalCarePerDay,
      10,
    );
  });

  test('CareSettingsDto.fromMap replie sur l\'ancien booléen umbilicalCareEnabled', () {
    expect(
      CareSettingsDto.fromMap(const {'umbilicalCareEnabled': false}).umbilicalCarePerDay,
      0,
    );
    expect(
      CareSettingsDto.fromMap(const {'umbilicalCareEnabled': true}).umbilicalCarePerDay,
      3,
    );
    expect(
      CareSettingsDto.fromMap(const {
        'umbilicalCarePerDay': 0,
        'umbilicalCareEnabled': true,
      }).umbilicalCarePerDay,
      0,
    );
  });

  test('CareSettingsDto.toMap écrit umbilicalCarePerDay et plus le booléen', () {
    final map = CareSettingsDto.toMap(const CareSettings(umbilicalCarePerDay: 2));
    expect(map['umbilicalCarePerDay'], 2);
    expect(map.containsKey('umbilicalCareEnabled'), isFalse);
  });
```

- [ ] **Étape 3 : tests du contrôleur (rouge)**

Dans `test/features/baby/presentation/baby_settings_controller_test.dart`, remplacer la ligne `expect(saved.careSettings.umbilicalCareEnabled, isFalse);` par :

```dart
    expect(saved.careSettings.umbilicalCarePerDay, 0);
```

puis ajouter juste après ce test :

```dart
  test('setCordFallenAt null remet le soin du nombril à 3', () async {
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    final disabled = profile.copyWith(
      cordFallenAt: DateTime(2026, 9, 12),
      careSettings: const CareSettings(umbilicalCarePerDay: 0),
    );
    final ok = await controller().setCordFallenAt(disabled, null);
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single
            as BabyProfile;
    expect(saved.cordFallenAt, isNull);
    expect(saved.careSettings.umbilicalCarePerDay, 3);
  });
```

- [ ] **Étape 4 : test du formulaire d'événement (rouge)**

Dans `test/features/events/presentation/event_form_sheet_test.dart`, ligne 119, remplacer `const CareSettings(umbilicalCareEnabled: false)` par :

```dart
      careSettings: const CareSettings(umbilicalCarePerDay: 0),
```

- [ ] **Étape 5 : test de la section Réglages (rouge)**

Ajouter à la fin de `main()` dans `test/features/baby/presentation/care_settings_section_test.dart` :

```dart
  testWidgets('le stepper nombril sauvegarde le nombre de soins par jour', (
    tester,
  ) async {
    final repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: CareSettingsSection(profile: profile),
        ),
      ),
      overrides: [
        babyRepositoryProvider.overrideWithValue(repo),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    expect(find.text('Soin du nombril par jour'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    // Ordre des steppers : Adrigyl, yeux, nez, nombril, bain, biberons.
    final plusButtons = find.widgetWithIcon(IconButton, Icons.add);
    await tester.tap(plusButtons.at(3));
    await tester.pumpAndSettle();
    final saved = verify(() => repo.saveProfile('ABCDEFGH', captureAny()))
        .captured
        .cast<BabyProfile>();
    expect(saved.last.careSettings.umbilicalCarePerDay, 4);
  });
```

- [ ] **Étape 6 : vérifier que les tests échouent**

Run: `flutter test test/features/dashboard/domain/compute_daily_care_status_test.dart test/features/baby/data/baby_profile_dto_test.dart`
Expected: échec de compilation, `umbilicalCarePerDay` inconnu sur `CareSettings`.

- [ ] **Étape 7 : entité**

Dans `lib/features/baby/domain/entities/care_settings.dart`, remplacer `@Default(true) bool umbilicalCareEnabled,` par :

```dart
    @Default(3) int umbilicalCarePerDay,
```

Puis : `dart run build_runner build -d`
Expected: `care_settings.freezed.dart` régénéré sans erreur.

- [ ] **Étape 8 : use case**

Dans `lib/features/dashboard/domain/use_cases/compute_daily_care_status.dart`, remplacer la ligne `if (settings.umbilicalCareEnabled) task(CareType.umbilicalCare, 1),` par :

```dart
      if (settings.umbilicalCarePerDay > 0)
        task(CareType.umbilicalCare, settings.umbilicalCarePerDay),
```

- [ ] **Étape 9 : DTO**

Dans `lib/features/baby/data/dtos/baby_profile_dto.dart`, la classe `CareSettingsDto` devient :

```dart
/// Conversion `CareSettings` ↔ map Firestore.
abstract final class CareSettingsDto {
  static Map<String, dynamic> toMap(CareSettings settings) => {
    'adrigylPerDay': settings.adrigylPerDay,
    'eyeCarePerDay': settings.eyeCarePerDay,
    'noseCarePerDay': settings.noseCarePerDay,
    'umbilicalCarePerDay': settings.umbilicalCarePerDay,
    'bathEveryDays': settings.bathEveryDays,
    'feedsPerDay': settings.feedsPerDay,
  };

  static int _readInt(
    Map<String, dynamic> map,
    String key,
    int fallback, {
    required int min,
    required int max,
  }) => ((map[key] as num?)?.toInt() ?? fallback).clamp(min, max);

  /// Documents antérieurs : seul le booléen `umbilicalCareEnabled` existe.
  static int _readUmbilicalCarePerDay(Map<String, dynamic> map) {
    final fallback = const CareSettings().umbilicalCarePerDay;
    if (map['umbilicalCarePerDay'] is num) {
      return _readInt(map, 'umbilicalCarePerDay', fallback, min: 0, max: 10);
    }
    return map['umbilicalCareEnabled'] == false ? 0 : fallback;
  }

  /// Borne chaque valeur à une plage sûre : un document modifié à la main ne doit jamais casser les calculs.
  static CareSettings fromMap(Map<String, dynamic> map) => CareSettings(
    adrigylPerDay: _readInt(map, 'adrigylPerDay', 1, min: 0, max: 10),
    eyeCarePerDay: _readInt(map, 'eyeCarePerDay', 1, min: 0, max: 10),
    noseCarePerDay: _readInt(map, 'noseCarePerDay', 1, min: 0, max: 10),
    umbilicalCarePerDay: _readUmbilicalCarePerDay(map),
    bathEveryDays: _readInt(map, 'bathEveryDays', 2, min: 1, max: 30),
    feedsPerDay: _readInt(map, 'feedsPerDay', 8, min: 1, max: 24),
  );
}
```

- [ ] **Étape 10 : contrôleur**

Dans `lib/features/baby/presentation/providers/baby_settings_controller.dart`, remplacer la méthode `setCordFallenAt` et son commentaire par :

```dart
  /// Renseigner la date désactive le soin du nombril ; l'effacer le remet à la valeur par défaut.
  Future<bool> setCordFallenAt(BabyProfile profile, DateTime? date) =>
      saveProfile(
        profile.copyWith(
          cordFallenAt: date,
          careSettings: profile.careSettings.copyWith(
            umbilicalCarePerDay: date == null
                ? const CareSettings().umbilicalCarePerDay
                : 0,
          ),
        ),
      );
```

- [ ] **Étape 11 : formulaire d'événement**

Dans `lib/features/events/presentation/widgets/event_form_sheet.dart`, remplacer le bloc `final umbilicalEnabled = ref.watch(babyProfileProvider).value?.careSettings.umbilicalCareEnabled ?? true;` par :

```dart
    final umbilicalPerDay = ref
        .watch(babyProfileProvider)
        .value
        ?.careSettings
        .umbilicalCarePerDay;
    final umbilicalEnabled = umbilicalPerDay == null || umbilicalPerDay > 0;
```

Le calcul de `visibleCares` qui suit reste inchangé.

- [ ] **Étape 12 : clé l10n**

Dans `lib/l10n/app_fr.arb`, ligne 110, remplacer `"settingsUmbilicalEnabled": "Soin du nombril",` par :

```json
  "settingsUmbilicalCarePerDay": "Soin du nombril par jour",
```

Puis : `flutter gen-l10n`
Expected: `S.settingsUmbilicalCarePerDay` disponible, `settingsUmbilicalEnabled` disparu.

- [ ] **Étape 13 : section Réglages**

Dans `lib/features/baby/presentation/widgets/care_settings_section.dart` :

1. Supprimer l'import `package:colette/core/theme/text_styles.dart` (plus utilisé).
2. Supprimer le `SwitchListTile(...)` en fin de `Column`.
3. Insérer, entre le stepper du nez et celui du bain :

```dart
          IntStepperRow(
            label: s.settingsUmbilicalCarePerDay,
            value: _settings.umbilicalCarePerDay,
            min: 0,
            max: 4,
            onChanged: (v) =>
                _update(_settings.copyWith(umbilicalCarePerDay: v)),
          ),
```

- [ ] **Étape 14 : formatage, analyse, tests**

Run:
```bash
dart format lib test && dart analyze && flutter test
```
Expected: `No issues found!` et tous les tests verts (au moins 150 + 6 nouveaux). Si `dart analyze` signale encore `umbilicalCareEnabled`, corriger l'occurrence indiquée avant de continuer.

- [ ] **Étape 15 : commit (stage sélectif)**

Le fichier `app_fr.arb` porte aussi des clés `theme*` non commitées d'un autre chantier. Stager uniquement la ligne du nombril :

```bash
cat > /tmp/arb-umbilical.patch <<'PATCH'
--- a/lib/l10n/app_fr.arb
+++ b/lib/l10n/app_fr.arb
@@ -110,1 +110,1 @@
-  "settingsUmbilicalEnabled": "Soin du nombril",
+  "settingsUmbilicalCarePerDay": "Soin du nombril par jour",
PATCH
git apply --cached --unidiff-zero /tmp/arb-umbilical.patch
git add lib/features/baby/domain/entities/care_settings.dart \
  lib/features/baby/domain/entities/care_settings.freezed.dart \
  lib/features/dashboard/domain/use_cases/compute_daily_care_status.dart \
  lib/features/baby/data/dtos/baby_profile_dto.dart \
  lib/features/baby/presentation/providers/baby_settings_controller.dart \
  lib/features/events/presentation/widgets/event_form_sheet.dart \
  lib/features/baby/presentation/widgets/care_settings_section.dart \
  test/features/dashboard/domain/compute_daily_care_status_test.dart \
  test/features/baby/data/baby_profile_dto_test.dart \
  test/features/baby/presentation/baby_settings_controller_test.dart \
  test/features/events/presentation/event_form_sheet_test.dart \
  test/features/baby/presentation/care_settings_section_test.dart
git diff --cached --stat
git commit -m "feat: nombre de soins du nombril par jour (défaut 3, 0 = désactivé)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
Expected : `git diff --cached --stat` liste exactement 13 fichiers, et `git diff lib/l10n/app_fr.arb` après le commit ne montre plus que les clés `theme*`.

---

### Tâche 2 : Cloud Functions — `withDefaults` et `pendingCares`

**Files:**
- Modify: `functions/src/lib/types.ts:3-19,71-82`
- Modify: `functions/src/lib/care-status.ts:24`
- Test: `functions/src/lib/types.test.ts`
- Test: `functions/src/lib/care-status.test.ts`

- [ ] **Étape 1 : tests `withDefaults` (rouge)**

Dans `functions/src/lib/types.test.ts` :

1. Dans le test `'valeurs nulles ou absentes'`, remplacer `umbilicalCareEnabled: null,` par `umbilicalCarePerDay: null,`.
2. Dans le test `'valeurs hors bornes'`, remplacer `umbilicalCareEnabled: true,` par `umbilicalCarePerDay: 3,`.
3. Dans le test `'valeurs normales'`, remplacer les deux occurrences de `umbilicalCareEnabled: false,` par `umbilicalCarePerDay: 2,`.
4. Remplacer le test `'nombril : activé sauf refus explicite'` par :

```ts
  it("nombril : repli sur l'ancien booléen umbilicalCareEnabled", () => {
    expect(withDefaults({ umbilicalCareEnabled: false }).umbilicalCarePerDay).toBe(0);
    expect(withDefaults({ umbilicalCareEnabled: true }).umbilicalCarePerDay).toBe(3);
    expect(withDefaults({ umbilicalCarePerDay: 0, umbilicalCareEnabled: true }).umbilicalCarePerDay).toBe(0);
    expect(withDefaults({ umbilicalCarePerDay: 42 }).umbilicalCarePerDay).toBe(10);
    expect(withDefaults({ umbilicalCarePerDay: Number.NaN }).umbilicalCarePerDay).toBe(3);
  });
```

- [ ] **Étape 2 : tests `pendingCares` (rouge)**

Dans `functions/src/lib/care-status.test.ts` :

1. Dans le test `'nombril désactivé et bain récent'`, remplacer `umbilicalCareEnabled: false` par `umbilicalCarePerDay: 0`.
2. Ajouter après ce test :

```ts
  it('nombril 3 par jour : deux soins faits encore en attente, trois faits absent', () => {
    const care = (hour: string) => ({ startAt: new Date(`2026-09-21T${hour}:00:00Z`), umbilicalCare: true });
    const twoDone = pendingCares({
      settings: DEFAULT_CARE_SETTINGS,
      todayEvents: [care('03'), care('05')],
      lastBathAt: null,
      now,
    });
    expect(twoDone).toContain('Soin du nombril');

    const threeDone = pendingCares({
      settings: DEFAULT_CARE_SETTINGS,
      todayEvents: [care('03'), care('04'), care('05')],
      lastBathAt: null,
      now,
    });
    expect(threeDone).not.toContain('Soin du nombril');
  });
```

- [ ] **Étape 3 : vérifier l'échec**

Run: `cd functions && npm test`
Expected: échec de type ou d'assertion sur `umbilicalCarePerDay`.

- [ ] **Étape 4 : `types.ts`**

Remplacer le type et le défaut :

```ts
export type CareSettings = {
  adrigylPerDay: number;
  eyeCarePerDay: number;
  noseCarePerDay: number;
  umbilicalCarePerDay: number;
  bathEveryDays: number;
  feedsPerDay: number;
};

export const DEFAULT_CARE_SETTINGS: CareSettings = {
  adrigylPerDay: 1,
  eyeCarePerDay: 1,
  noseCarePerDay: 1,
  umbilicalCarePerDay: 3,
  bathEveryDays: 2,
  feedsPerDay: 8,
};

/** Réglages tels que stockés, y compris l'ancien booléen des documents antérieurs. */
export type StoredCareSettings = Partial<CareSettings> & { umbilicalCareEnabled?: boolean };
```

Remplacer `careSettings?: Partial<CareSettings>;` dans `BabyDoc` par `careSettings?: StoredCareSettings;`.

Remplacer `withDefaults` par :

```ts
/** Documents antérieurs : seul le booléen `umbilicalCareEnabled` existe. */
function readUmbilicalCarePerDay(raw: StoredCareSettings): number {
  const fallback = DEFAULT_CARE_SETTINGS.umbilicalCarePerDay;
  if (typeof raw.umbilicalCarePerDay === 'number') return clamped(raw.umbilicalCarePerDay, 0, 10, fallback);
  return raw.umbilicalCareEnabled === false ? 0 : fallback;
}

/** Mêmes valeurs par défaut et mêmes bornes que `CareSettingsDto.fromMap` côté client. */
export function withDefaults(settings: StoredCareSettings | undefined): CareSettings {
  const raw = settings ?? {};
  return {
    adrigylPerDay: clamped(raw.adrigylPerDay, 0, 10, DEFAULT_CARE_SETTINGS.adrigylPerDay),
    eyeCarePerDay: clamped(raw.eyeCarePerDay, 0, 10, DEFAULT_CARE_SETTINGS.eyeCarePerDay),
    noseCarePerDay: clamped(raw.noseCarePerDay, 0, 10, DEFAULT_CARE_SETTINGS.noseCarePerDay),
    umbilicalCarePerDay: readUmbilicalCarePerDay(raw),
    bathEveryDays: clamped(raw.bathEveryDays, 1, 30, DEFAULT_CARE_SETTINGS.bathEveryDays),
    feedsPerDay: clamped(raw.feedsPerDay, 1, 24, DEFAULT_CARE_SETTINGS.feedsPerDay),
  };
}
```

- [ ] **Étape 5 : `care-status.ts`**

Remplacer la ligne du nombril dans `pendingCares` par :

```ts
  if (settings.umbilicalCarePerDay > 0 && count('umbilicalCare') < settings.umbilicalCarePerDay)
    pending.push(CARE_LABELS.umbilicalCare);
```

- [ ] **Étape 6 : tests et build**

Run: `cd functions && npm test && npm run build`
Expected: tous les tests verts, `tsc` sans erreur. Vérifier aussi : `grep -rn umbilicalCareEnabled functions/src` ne renvoie que `types.ts` (type `StoredCareSettings`, fonction de repli) et `types.test.ts`.

- [ ] **Étape 7 : commit**

```bash
git add functions/src/lib/types.ts functions/src/lib/types.test.ts \
  functions/src/lib/care-status.ts functions/src/lib/care-status.test.ts
git commit -m "feat(functions): nombre de soins du nombril par jour avec repli sur l'ancien booléen

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Tâche 3 : Documentation

**Files:**
- Modify: `docs/superpowers/specs/2026-09-21-colette-v1-design.md:169,263,312,325`
- Modify: `docs/superpowers/specs/2026-09-22-umbilical-care-per-day-design.md` (section 5, dernière ligne)

- [ ] **Étape 1 : spec v1**

Ligne 169, remplacer :
```
      umbilicalCareEnabled: true      passe à false automatiquement quand cordFallenAt est renseigné
```
par :
```
      umbilicalCarePerDay: 3          passe à 0 quand cordFallenAt est renseigné, revient à 3 quand elle est effacée
```

Ligne 263, remplacer la ligne du tableau par :
```
| Soin du nombril | `umbilicalCarePerDay` fois par jour civil ; jamais attendu si 0 |
```

Ligne 312, remplacer `(masquée si `umbilicalCareEnabled` est faux)` par `(masquée si `umbilicalCarePerDay` vaut 0)`.

Ligne 325, remplacer `nombril activé` par `nombril / jour`.

- [ ] **Étape 2 : spec du 22 septembre**

Dans `docs/superpowers/specs/2026-09-22-umbilical-care-per-day-design.md`, remplacer la dernière ligne de la section 5 :
```
Documentation : spec v1 (sections 5, 6.2 et 6.6) et plans mis à jour pour refléter le nouveau champ.
```
par :
```
Documentation : spec v1 (sections 5, 6.2 et 6.6) mise à jour. Les plans v1 sont historiques et ne sont pas modifiés.
```

- [ ] **Étape 3 : commit**

```bash
git add docs/superpowers/specs/2026-09-21-colette-v1-design.md \
  docs/superpowers/specs/2026-09-22-umbilical-care-per-day-design.md
git commit -m "docs: spec v1 alignée sur le nombre de soins du nombril par jour

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Tâche 4 : Vérification finale

- [ ] **Étape 1 : suite complète**

```bash
dart format --set-exit-if-changed lib test && dart analyze && flutter test && (cd functions && npm test && npm run build)
```
Expected : aucun fichier reformaté, `No issues found!`, tests Flutter et vitest verts, `tsc` silencieux.

- [ ] **Étape 2 : plus aucune trace de l'ancien champ hors repli**

```bash
grep -rn "umbilicalCareEnabled\|settingsUmbilicalEnabled" lib test functions/src docs/superpowers/specs
```
Expected : uniquement `baby_profile_dto.dart` (repli), `baby_profile_dto_test.dart`, `types.ts` (repli), `types.test.ts`, et la section 4 de la spec du 22 septembre.

- [ ] **Étape 3 : contrôle visuel sur simulateur**

Lancer l'app sur un simulateur iPhone, ouvrir Réglages : le stepper « Soin du nombril par jour » affiche 3 pour un foyer existant, monte à 4 et descend à 0, en thème clair et sombre. À 0, la puce « Soin du nombril » disparaît du formulaire d'événement et de la carte du jour. Renseigner « Chute du cordon » ramène le stepper à 0.
