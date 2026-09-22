# Libellés des soins dans le journal — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Afficher, dans chaque ligne du journal, une puce icône + libellé par soin coché et une puce icône + « N ml » pour le biberon.

**Architecture:** Changement limité à la couche présentation de la feature `events`. Le widget `EventTile` remplace ses deux widgets privés (`_CareDot`, `_BottleBadge`) par un unique `_CareChip`. Libellés fournis par `CareTypeUi.label` et la clé `bottleMl`, déjà existants.

**Tech Stack:** Flutter, Riverpod 3, tokens `design_tokens.dart`, `flutter_test` + `mocktail` via `pumpApp`.

Spec : `docs/superpowers/specs/2026-09-22-journal-care-labels-design.md`.

---

### Task 1 : Puces icône + libellé dans `EventTile`

**Files:**
- Modify: `lib/features/events/presentation/widgets/event_tile.dart`
- Test: `test/features/events/presentation/timeline_page_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

Dans le premier test `affiche les événements groupés par jour`, ajouter après `expect(find.text('120 ml'), findsOneWidget);` :

```dart
    expect(find.text('Couche'), findsOneWidget);
    expect(find.text('Bain'), findsOneWidget);
    expect(find.byIcon(Icons.local_drink_outlined), findsOneWidget);
```

- [ ] **Step 2 : Vérifier qu'il échoue**

Run: `flutter test test/features/events/presentation/timeline_page_test.dart`
Expected: FAIL, `find.text('Couche')` trouve 0 widget.

- [ ] **Step 3 : Implémenter `_CareChip`**

Dans `event_tile.dart`, remplacer le contenu du `Wrap` :

```dart
                      children: [
                        for (final type in event.checkedCares)
                          _CareChip(
                            icon: type.icon,
                            label: type.label(s),
                            color: context.appColor(type.color),
                          ),
                        if (event.bottleMl case final ml?)
                          _CareChip(
                            icon: Icons.local_drink_outlined,
                            label: s.bottleMl(ml),
                            color: context.appColor(AppColors.categoryFeeding),
                          ),
                      ],
```

Et remplacer `_CareDot` et `_BottleBadge` par :

```dart
/// Puce icône + libellé d'un soin, teintée par sa catégorie.
class _CareChip extends StatelessWidget {
  const _CareChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppOpacity.light.applyTo(color),
        borderRadius: AppRadius.round.circular,
      ),
      child: Row(
        mainAxisSize: .min,
        spacing: AppSpacing.xs.value,
        children: [
          Icon(icon, size: AppSize.xs.value, color: color),
          Text(
            label,
            style: Theme.of(context).coletteTextStyles.label
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
```

Mettre à jour le commentaire de classe : `/// Ligne du journal : heure, puces des soins et du biberon, note. Glisser pour supprimer.`

- [ ] **Step 4 : Vérifier que le test passe**

Run: `flutter test test/features/events/presentation/timeline_page_test.dart`
Expected: PASS.

- [ ] **Step 5 : Format, analyse, suite complète**

Run: `dart format lib test && dart analyze && flutter test`
Expected: aucune erreur, aucun avertissement.

- [ ] **Step 6 : Contrôle visuel**

Lancer sur simulateur iPhone, onglet Journal, en clair puis en sombre, avec un événement cumulant plusieurs soins et un biberon : les puces passent à la ligne et restent lisibles.

- [ ] **Step 7 : Commit**

```bash
git add lib/features/events/presentation/widgets/event_tile.dart test/features/events/presentation/timeline_page_test.dart docs/superpowers/plans/2026-09-22-journal-care-labels.md
git commit -m "feat: libellés des soins et du biberon dans les lignes du journal"
```
