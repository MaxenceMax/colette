# Carrousel des prochains rendez-vous — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** la carte « Prochain rendez-vous » de l'onglet Santé fait défiler les 5 prochains RDV programmés, et la section « Rendez-vous programmés » en liste la totalité.

**Architecture :** le getter de domaine `MedicalTimeline.nextAppointments` fournit les 5 RDV. Le widget générique `AppointmentCarousel` affiche un `PageView` sur une couche de mesure `IndexedStack(index: null)` : la hauteur est celle de la plus grande carte, sans valeur en dur. Sous le carrousel, des points indiquent la position. `NextAppointmentCard` calcule la proximité de chaque RDV.

**Tech Stack :** Flutter, Riverpod 3 (codegen), flutter_test, l10n ARB.

Spec : `docs/superpowers/specs/2026-09-27-appointment-carousel-design.md`.

---

### Task 1 : `MedicalTimeline.nextAppointments`

**Fichiers :**
- Modifier : `lib/features/health/domain/entities/medical_timeline.dart` (sous `nextAppointment`)
- Test : `test/features/health/domain/medical_timeline_test.dart` (dans le groupe qui contient `nextAppointment : le premier programmé, ou null`)

- [ ] **Étape 1 : test rouge**

```dart
    test('nextAppointments : les 5 premiers programmés, datés et triés', () {
      final many = MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
        appointments: [
          for (var d = 7; d >= 1; d--)
            custom('rdv$d', DateTime(2026, 10, d, 9), .scheduled),
          custom('fait', DateTime(2026, 10, 1, 8), .done),
        ],
      );
      expect(
        [
          for (final i in many.nextAppointments)
            (i as AppointmentItem).appointment.id,
        ],
        ['rdv1', 'rdv2', 'rdv3', 'rdv4', 'rdv5'],
      );
      expect(const MedicalTimeline(entries: []).nextAppointments, isEmpty);
    });
```

- [ ] **Étape 2 :** `flutter test test/features/health/domain/medical_timeline_test.dart` → échec (le getter n'existe pas).
- [ ] **Étape 3 : implémentation**

```dart
  /// Nombre de RDV mis en avant dans le carrousel de l'onglet Santé.
  static const nextAppointmentsLimit = 5;

  /// Les [nextAppointmentsLimit] prochains RDV programmés, du plus proche au
  /// plus lointain.
  List<MedicalTimelineItem> get nextAppointments =>
      scheduled.take(nextAppointmentsLimit).toList();
```

Si la classe est `@freezed`, un getter nécessite le constructeur privé `const MedicalTimeline._()`. Vérifier que ce constructeur existe (c'est déjà le cas si `scheduled` y est défini).

- [ ] **Étape 4 :** relancer le test → succès.
- [ ] **Étape 5 :** `git add lib/features/health/domain/entities/medical_timeline.dart test/features/health/domain/medical_timeline_test.dart && git commit -m "feat: les 5 prochains rendez-vous programmés de la frise"`

### Task 2 : `ScheduledSection` liste tous les RDV

**Fichiers :**
- Modifier : `lib/features/health/presentation/widgets/scheduled_section.dart`
- Modifier : `lib/l10n/app_fr.arb` (`healthSectionScheduled`)
- Tests : `test/features/health/presentation/scheduled_section_test.dart`, `test/features/health/presentation/health_page_test.dart`

- [ ] **Étape 1 : tests rouges.** Dans `scheduled_section_test.dart`, remplacer `'Aussi programmés'` par `'Rendez-vous programmés'`. Renommer le 2ᵉ test en `'liste tous les RDV, le premier compris, avec bloc date et détail'` et remplacer ses attentes par :

```dart
    expect(find.text('Rendez-vous programmés'), findsOneWidget);
    expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('nov.'), findsNWidgets(2));
    expect(find.text('Ostéopathe'), findsOneWidget);
    expect(find.text('15h00 · RDV libre'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('déc.'), findsOneWidget);
    expect(find.text('09h30 · Dr Martin'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
```

Dans `health_page_test.dart`, remplacer aussi chaque `'Aussi programmés'` par `'Rendez-vous programmés'`.

- [ ] **Étape 2 :** `flutter test test/features/health/presentation/scheduled_section_test.dart` → échec.
- [ ] **Étape 3 : implémentation.** Dans l'ARB : `"healthSectionScheduled": "Rendez-vous programmés",`. Dans la section, supprimer `final rest = items.skip(1);`, itérer sur `items`, et remplacer la doc de la classe par :

```dart
/// Section « Rendez-vous programmés » : tous les RDV programmés, du plus
/// proche au plus lointain. Rien s'il y en a moins de deux (la carte
/// « Prochain rendez-vous » suffit).
```

Puis `flutter gen-l10n`.

- [ ] **Étape 4 :** relancer le test de la section → succès. `health_page_test` est traité en Task 4.
- [ ] **Étape 5 :** commit `feat: la section Rendez-vous programmés liste tous les RDV`, avec les fichiers ARB, section et tests.

### Task 3 : widget `AppointmentCarousel`

**Fichiers :**
- Créer : `lib/features/health/presentation/widgets/appointment_carousel.dart`
- Modifier : `lib/l10n/app_fr.arb` (après `healthNoAppointment`)
- Test : `test/features/health/presentation/appointment_carousel_test.dart`

- [ ] **Étape 1 : test rouge**

```dart
import 'package:colette/features/health/presentation/widgets/appointment_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpCarousel(WidgetTester tester, List<String> labels) =>
      pumpApp(
        tester,
        Scaffold(
          body: ListView(
            children: [
              AppointmentCarousel(pages: [for (final l in labels) Text(l)]),
            ],
          ),
        ),
      );

  testWidgets('affiche la première page et un point par page', (
    tester,
  ) async {
    await pumpCarousel(tester, ['A', 'B', 'C']);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.bySemanticsLabel('Rendez-vous 1 sur 3'), findsOneWidget);
  });

  testWidgets('glisser vers la gauche passe à la page suivante', (
    tester,
  ) async {
    await pumpCarousel(tester, ['A', 'B', 'C']);
    await tester.fling(find.text('A'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(find.bySemanticsLabel('Rendez-vous 2 sur 3'), findsOneWidget);
  });

  testWidgets('hauteur de la plus grande page', (tester) async {
    await pumpCarousel(tester, ['court', 'long\nsur\ntrois lignes']);
    final short = tester.getSize(find.byType(PageView)).height;
    expect(short, greaterThan(tester.getSize(find.text('court')).height));
  });

  testWidgets('la liste raccourcit : revient sur la dernière page valide', (
    tester,
  ) async {
    await pumpCarousel(tester, ['A', 'B', 'C']);
    await tester.fling(find.text('A'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.text('B'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    await pumpCarousel(tester, ['A', 'B']);
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(find.bySemanticsLabel('Rendez-vous 2 sur 2'), findsOneWidget);
  });
}
```

- [ ] **Étape 2 :** `flutter test test/features/health/presentation/appointment_carousel_test.dart` → échec (le fichier n'existe pas).
- [ ] **Étape 3 : implémentation.** ARB :

```json
  "healthAppointmentPosition": "Rendez-vous {index} sur {count}",
  "@healthAppointmentPosition": { "placeholders": { "index": { "type": "int" }, "count": { "type": "int" } } },
```

puis `flutter gen-l10n`. Widget :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Carrousel de cartes de RDV, haut comme la plus grande, avec points de
/// position.
class AppointmentCarousel extends StatefulWidget {
  const AppointmentCarousel({super.key, required this.pages});

  /// Cartes à faire défiler, dans l'ordre.
  final List<Widget> pages;

  @override
  State<AppointmentCarousel> createState() => _AppointmentCarouselState();
}

class _AppointmentCarouselState extends State<AppointmentCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(AppointmentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final last = widget.pages.length - 1;
    if (_index <= last) return;
    _index = last;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) _controller.jumpToPage(last);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (final page in widget.pages)
        Padding(padding: AppSpacing.xs.horizontal, child: page),
    ];
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm.value,
      children: [
        Stack(
          fit: .passthrough,
          children: [
            // Mesure : prend la taille de la plus grande page, sans la
            // peindre ni l'exposer aux taps et à la sémantique.
            IndexedStack(index: null, sizing: .passthrough, children: pages),
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => pages[i],
              ),
            ),
          ],
        ),
        _PageDots(index: _index, count: pages.length),
      ],
    );
  }
}

/// Points de position : actif en `primary`, les autres en `textSecondary`.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.of(context).healthAppointmentPosition(index + 1, count),
      child: Row(
        mainAxisAlignment: .center,
        spacing: AppSpacing.xs.value,
        children: [
          for (var i = 0; i < count; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                shape: .circle,
                color: context.appColor(
                  i == index ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              child: AppSize.nano.square,
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Étape 4 :** relancer le test → succès.
- [ ] **Étape 5 :** commit `feat: carrousel de rendez-vous avec points de position` (ARB, widget, test).

### Task 4 : `NextAppointmentCard` en carrousel

**Fichiers :**
- Modifier : `lib/features/health/presentation/widgets/next_appointment_card.dart`
- Tests : `test/features/health/presentation/next_appointment_card_test.dart`, `test/features/health/presentation/health_page_test.dart`

- [ ] **Étape 1 : tests rouges** dans `next_appointment_card_test.dart`. Ajouter le helper et les tests suivants :

```dart
  AppointmentItem rdv(String title, DateTime at) => AppointmentItem(
    makeAppointment(id: title, title: title, appointmentAt: at),
    MedicalStageStatus.scheduled,
  );

  testWidgets('un seul RDV : pas de carrousel', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [],
        appointments: [rdv('ORL', DateTime(2026, 10, 25, 8))],
      ),
    );
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('plusieurs RDV : carrousel, chaque carte avec sa proximité', (
    tester,
  ) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [],
        appointments: [
          rdv('ORL', DateTime(2026, 10, 20, 15)),
          rdv('Pédiatre', DateTime(2026, 10, 30, 9)),
          rdv('Ostéo', DateTime(2026, 11, 5, 9)),
        ],
      ),
    );
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Aujourd\'hui à 15h00'), findsOneWidget);
    expect(find.bySemanticsLabel('Rendez-vous 1 sur 3'), findsOneWidget);
    await tester.fling(find.text('ORL'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Pédiatre'), findsOneWidget);
    expect(find.text('RDV libre'), findsWidgets);
    expect(find.text('dans 10 jours'), findsOneWidget);
  });

  testWidgets('plus de 5 RDV : 5 cartes seulement', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [],
        appointments: [
          for (var d = 21; d <= 27; d++) rdv('RDV $d', DateTime(2026, 10, d, 9)),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Rendez-vous 1 sur 5'), findsOneWidget);
  });
```

Dans `health_page_test.dart` (test « ordre des blocs »), le premier RDV (Ostéopathe) apparaît désormais dans le carrousel **et** dans la liste. Remplacer `expect(find.text('Ostéopathe'), findsOneWidget);` par `findsNWidgets(2)`. Ajouter `expect(find.byType(PageView), findsOneWidget);`.

- [ ] **Étape 2 :** `flutter test test/features/health/presentation/next_appointment_card_test.dart` → échec.
- [ ] **Étape 3 : implémentation.** Dans `NextAppointmentCard.build` :

```dart
    final timeline = ref.watch(medicalTimelineProvider);
    final today = ref.watch(todayProvider);
    if (timeline == null) return const SizedBox.shrink();
    final bodies = [
      for (final item in timeline.nextAppointments)
        if (item.appointmentAt case final at?)
          _AppointmentBody(
            item: item,
            appointmentAt: at,
            proximity: const ComputeAppointmentProximity()(
              appointmentAt: at,
              today: today,
            ),
          ),
    ];
```

puis, pour les enfants de la `Column` :

```dart
        switch (bodies) {
          [] => const _EmptyCard(),
          [final only] => only,
          _ => AppointmentCarousel(pages: bodies),
        },
```

Importer `compute_appointment_proximity.dart` et `appointment_carousel.dart`, et retirer l'usage de `nextAppointmentProximityProvider`, qui reste utilisé par `AppointmentCard`. Mettre à jour la doc de la classe : « le ou les prochains RDV programmés (jusqu'à 5, en carrousel) ».

- [ ] **Étape 4 :** `flutter test test/features/health` → succès.
- [ ] **Étape 5 :** commit `feat: carrousel des 5 prochains rendez-vous sur l'onglet Santé`.

### Task 5 : vérification

- [ ] `dart run build_runner build -d` (aucun fichier annoté modifié, sauf si l'entité est `freezed`), `dart format lib test`, `dart analyze`, `flutter test`.
- [ ] Simulateur iPhone, onglet Santé, thèmes clair et sombre : le carrousel glisse, sa hauteur est stable et les points suivent. S'il n'y a pas assez de RDV sur le foyer du simulateur, se limiter aux tests : pas de foyer de test en production sans accord.
