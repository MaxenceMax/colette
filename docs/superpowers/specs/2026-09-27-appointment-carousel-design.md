# Carrousel des prochains rendez-vous (onglet Santé)

Date : 2026-09-27. Base : `main` (`9d933a8`). Complète la spec `2026-09-24-health-review-design.md`.

## 1. Objectif

Décisions prises le 2026-09-27 avec Maxence :

1. La carte « Prochain rendez-vous » en tête de l'onglet Santé devient un carrousel qui fait défiler les **5 prochains RDV programmés**, c'est-à-dire ceux qui ont une date renseignée, à venir et non faits (statut `scheduled`). Les étapes sans date n'y figurent jamais.
2. La section « Aussi programmés » liste désormais **tous** les RDV programmés (le premier compris), dès qu'il y en a au moins deux. Le carrousel met en avant, la liste donne la vue complète.
3. La tuile Rendez-vous de l'onglet Aujourd'hui (`AppointmentCard`) ne change pas.

## 2. Domaine

### 2.1 `MedicalTimeline`

```dart
/// Nombre de RDV mis en avant dans le carrousel de l'onglet Santé.
static const nextAppointmentsLimit = 5;

/// Les [nextAppointmentsLimit] prochains RDV programmés, du plus proche au
/// plus lointain.
List<MedicalTimelineItem> get nextAppointments =>
    scheduled.take(nextAppointmentsLimit).toList();
```

`nextAppointment` et `scheduled` sont conservés tels quels.

## 3. Présentation

### 3.1 `NextAppointmentCard`

- Le titre « Prochain rendez-vous » est conservé.
- La carte lit `timeline.nextAppointments` et `todayProvider`. Elle ne lit plus `nextAppointmentProximityProvider`, que seule la tuile Aujourd'hui continue d'utiliser.
- Selon le nombre de RDV :
  - **0 RDV** : carte vide actuelle (`_EmptyCard`).
  - **1 RDV** : une seule carte `_AppointmentBody`, sans carrousel ni points.
  - **2 à 5 RDV** : `AppointmentCarousel` avec une `_AppointmentBody` par page.
- La proximité de chaque RDV est calculée par `ComputeAppointmentProximity()(appointmentAt:, today:)`. `_AppointmentBody` reçoit `item`, `appointmentAt` et `proximity` comme aujourd'hui. Toutes les cartes gardent le même style (`primaryContainer`) et restent tapables : le tap ouvre `showTimelineItemSheet`.

### 3.2 `AppointmentCarousel` (nouveau fichier `widgets/appointment_carousel.dart`)

- Widget public générique `AppointmentCarousel({required List<Widget> pages})`, qui contient aussi les points (`_PageDots`, section 3.3). Le garder à part permet de laisser `next_appointment_card.dart` sous 300 lignes.
- `StatefulWidget` qui détient un `PageController`, disposé dans `dispose()`, et l'index de la page courante. C'est un état d'UI pur, sans logique métier.
- **Hauteur sans valeur en dur** : un `Stack` contient
  1. un `IndexedStack(index: null)` qui contient toutes les cartes : il prend la taille de la plus grande, sans rien peindre, sans recevoir de tap, sans sémantique, et les finders de test l'ignorent ;
  2. un `Positioned.fill` qui contient `PageView.builder` (viewport pleine largeur).

  La hauteur reste stable pendant le glissement et suit la taille de texte d'iOS.
- Chaque page, visible comme cachée, est enveloppée dans le même padding horizontal `AppSpacing.xs`. Ce padding sépare les cartes pendant le glissement, et la mesure se fait à la largeur réelle d'affichage.
- Si la liste change (un RDV passe, un autre est ajouté) et que l'index courant dépasse la nouvelle longueur, `didUpdateWidget` ramène à la dernière page valide.

### 3.3 `_PageDots`

- Une rangée centrée de points de taille `AppSize.nano`, espacés de `AppSpacing.xs`, sous le carrousel (espacement `AppSpacing.sm`).
- Point actif en `AppColors.primary`, les autres en `AppColors.textSecondary` avec la même forme (cercle `AppRadius.full` ou `BoxShape.circle`).
- `Semantics(label: s.healthAppointmentPosition(index + 1, count))`, avec la nouvelle clé `"healthAppointmentPosition": "Rendez-vous {index} sur {count}"`. Les points ne sont pas tapables.

### 3.4 `ScheduledSection`

- Elle affiche tous les `items`, sans `skip(1)`, et reste masquée s'il y a moins de deux RDV.
- La doc de la classe est mise à jour. Le titre « Aussi programmés » est renommé « Rendez-vous programmés » (clé `healthSectionScheduled`), puisque la liste inclut désormais le premier RDV.

## 4. Tests

- **Domaine** (`medical_timeline_test.dart`) : `nextAppointments` contient au plus 5 éléments, triés par date, sans étape non datée, et une liste vide sans RDV programmé.
- **Carte** (`next_appointment_card_test.dart`) :
  - 0 RDV : texte « Pas de rendez-vous programmé » ;
  - 1 RDV : aucun `PageView` ;
  - 3 RDV : 3 points, la première carte visible ; un glissement vers la gauche affiche la 2ᵉ carte et change le point actif ;
  - 7 RDV : 5 pages seulement ;
  - tap sur une carte : la fiche s'ouvre.
- **Section** (`scheduled_section_test.dart`) : 3 RDV donnent 3 lignes, le premier compris, et 1 RDV ne donne rien.
- `health_page_test.dart` : adapter les attentes qui dépendaient de `skip(1)`.
