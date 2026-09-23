# Colette — RDV libres : examens et vaccins hors calendrier

Date : 2026-09-23. Complète la spec du suivi médical (`2026-09-23-health-follow-up-design.md`), qui laissait les « RDV libres (maladie, spécialiste) » hors périmètre. Sous-projet C du volet santé.

## 1. Problème

Le calendrier de référence couvre les examens obligatoires et les vaccins du carnet. Les parents ont aussi des rendez-vous qui n'y figurent pas : ostéopathe, ORL, pédiatre pour une maladie, rattrapage vaccinal, vaccin de saison (grippe, VRS). Ils veulent :

- ajouter un rendez-vous avec un titre libre, une date et une heure, un praticien et une note ;
- le retrouver dans le Calendrier iOS partagé, avec les mêmes alarmes que les étapes officielles ;
- le voir dans l'onglet Santé, mêlé aux étapes du calendrier ;
- le marquer comme fait et noter les vaccins reçus ce jour-là, connus ou non du calendrier, avec nom commercial et lot.

Décisions prises le 2026-09-23 avec Maxence : RDV libres mêlés aux étapes (pas de section à part) ; rappel par le Calendrier iOS, pas par le digest du matin ; vaccins de la liste connue plus des vaccins à nom libre. Le même jour, Maxence a demandé que la Santé devienne un onglet à part entière de la barre du bas, que l'onglet Aujourd'hui soit centré avec un design distinct de menu principal, et que la carte Santé disparaisse de l'accueil (les rappels du Calendrier iOS restent).

## 1 bis. Navigation

- Cinq branches dans `StatefulShellRoute.indexedStack`, dans cet ordre : Journal (`/journal`), Assiette (`/plate`), **Aujourd'hui** (`/today`, index 2), Santé (`/health`), Réglages (`/settings`). La branche initiale reste Aujourd'hui (`initialLocation: AppRoutes.today`, comme aujourd'hui).
- `AppRoutes.health` devient `/health` ; la page Santé quitte l'imbrication sous `/today`. Croissance, Sommeil et Documents restent sous `/today`.
- `MainShell` remplace `NavigationBar` par une barre maison `ColetteTabBar` (`lib/app/widgets/colette_tab_bar.dart`) : quatre destinations classiques (icône, libellé, `Semantics` bouton, `selected`) réparties autour d'un bouton central rond surélevé (`Icons.wb_sunny`, disque `primary`, icône `onPrimary`, ombre légère) qui dépasse au-dessus de la barre et n'a pas de libellé ; `Tooltip`/`Semantics` « Aujourd'hui » pour l'accessibilité. Le bouton central prend un anneau `primaryContainer` quand la branche Aujourd'hui est active. Hauteur de barre et diamètre du disque en `AppSize`, aucune valeur en dur. Tap sur l'onglet courant : retour à la racine de la branche (`initialLocation: true`), comme aujourd'hui.
- `HealthCard` est supprimée de l'accueil (fichier et test retirés) ; la carte Santé ne revient pas. `HealthSyncGate`, le snapshot `medicalReminder` et la synchronisation Calendrier ne changent pas.
- Route de notification et liens internes vers la Santé (`context.push(AppRoutes.health)`) passent par `context.go(AppRoutes.health)` pour activer la branche.

## 2. Domaine (`lib/features/health/domain`)

| Élément | Rôle |
| --- | --- |
| `CustomAppointment` (freezed) | Rendez-vous hors calendrier : `id` (UUID, identifiant Firestore), `title`, `appointmentAt` (obligatoire), `practitioner?`, `doneAt?`, `note?`, `vaccines: List<CustomVaccine>`, `updatedAt`, `updatedByDeviceId`. |
| `CustomVaccine` (freezed) | Injection reçue lors d'un RDV libre : `code: VaccineCode?` (vaccin connu) ou `name: String?` (vaccin libre, ex. « Grippe »), exactement l'un des deux ; `givenAt`, `brand?`, `lot?`. Getter `isKnown => code != null`. |
| `MedicalStageStatus` (existant) | Réutilisé pour un RDV libre avec trois valeurs seulement : `done` si `doneAt` ; sinon `appointmentPassed` si `appointmentAt < now` ; sinon `scheduled`. Jamais `late`, `due` ni `upcoming` : un RDV libre n'a pas de fenêtre d'âge. |
| `ComputeCustomAppointmentStatus` (pur) | Applique la règle ci-dessus. |
| `MedicalTimelineItem` (sealed, freezed) | `StageItem(entry: MedicalTimelineEntry)` ou `AppointmentItem(appointment: CustomAppointment, status: MedicalStageStatus)`. Getters communs : `status`, `anchorDate` (étape : `dueFrom` ; RDV libre : `appointmentAt`). |
| `MedicalTimeline` (existant, étendu) | Reçoit `entries` (étapes, ordre du calendrier) et `appointments` (RDV libres). Expose `items` : les étapes dans leur ordre, chaque RDV libre inséré **avant la première étape dont `dueFrom` est strictement postérieur à son `appointmentAt`** (après la dernière sinon) ; deux RDV libres au même endroit gardent l'ordre chronologique, puis l'ordre des `id`. `next` devient le premier item de `items` dont le statut n'est pas `done` (plus de consommateur dans l'app après le retrait de la carte ; conservé pour la frise). |
| `ComputeMedicalTimeline` (existant, étendu) | Paramètre supplémentaire `appointments`. |
| `ComputeMedicalReminderSnapshot` (existant, inchangé) | Ne regarde que `entries` : un RDV libre a toujours une date, rien à rappeler. Le document `medicalReminder` et la Cloud Function `morningDigest` ne changent pas. |
| `ReconcileCalendar` (existant, étendu) | Paramètre supplémentaire `appointments` et `titleOfAppointment(CustomAppointment)`. URL `colette://rdv/custom/{id}` (`ReconcileCalendar.customUrlOf`). Brouillon : titre « {titre} · {prénom} », 30 minutes, notes = praticien, mêmes alarmes (veille 18 h, 1 h avant), même fenêtre `[hier, +2 ans)`, exclu si `doneAt` posé. La suppression d'un RDV libre supprime l'événement par la logique d'orphelins existante. |
| `ValidateCustomAppointment` (pur) | `Either<ValidationFailure, CustomAppointment>` : titre non vide après `trim` (`ValidationReason.medicalTitleRequired`) ; chaque vaccin libre a un nom non vide et aucun vaccin ne porte à la fois `code` et `name` (`ValidationReason.medicalVaccineNameRequired`) ; RDV, visite faite et injections après la naissance (`medicalDateBeforeBirth`) ; visite faite et injections pas dans le futur, tolérance 5 minutes (`medicalDateInFuture`). Titre, praticien, note, nom, marque et lot sont `trim`és, vides → `null`. |

Un RDV libre n'a pas de notion de « vide » : il existe tant qu'il n'est pas supprimé.

## 3. Données (`lib/features/health/data`)

- Collection `households/{code}/medicalAppointments/{id}` (`FirestorePaths.medicalAppointments`). Les règles Firestore couvrent déjà toute sous-collection d'un foyer ; le commentaire des règles est mis à jour.
- `CustomAppointmentDto` : `toMap` avec clés absentes plutôt que nulles ; `vaccines` est un tableau de maps `{code?, name?, givenAt, brand?, lot?}`. `fromDoc` renvoie `null` si `title`, `appointmentAt` ou `updatedAt` est absent ou d'un mauvais type ; un vaccin illisible (ni `code` connu ni `name`, ou `givenAt` invalide) est ignoré. Dates en `Timestamp`.
- `MedicalRepository` : `watchAppointments(code)` (triés par `appointmentAt` puis `id`), `fetchAppointmentsFromServer(code)` (`Source.server`, échoue hors ligne), `saveAppointment(code, appointment)` (remplace le document), `deleteAppointment(code, id)`.
- `FirestoreHealthSync` lit visites **et** RDV libres sur le serveur ; si l'une des deux lectures échoue, rien n'est écrit (même règle qu'aujourd'hui).

## 4. Présentation (`lib/features/health/presentation`)

- Providers : `medicalAppointmentsProvider` (stream, `retry: noRetry`) ; `medicalTimelineProvider` reste `null` tant que visites **ou** RDV libres ne sont pas lus. `HealthSyncGate` relance la sync à chaque émission des deux flux.
- `CustomAppointmentController` (`@riverpod`, `FutureOr<void> build`) : `save(appointment, birthDate)` et `delete(id)`, même schéma que `MedicalVisitController` (lecture des dépendances avant l'`await`, `AsyncLoading` → `AsyncData` / `AsyncError`, puis `healthSync.sync()`). Identifiant d'un nouveau RDV : `idGeneratorProvider`.
- `HealthPage` : bouton « + » (`IconButton`, `Icons.add`) dans l'`AppBar`, qui ouvre la feuille de création. Les sections « En retard », « À faire », « À venir », « Faites » sont construites sur `timeline.items` : un `StageItem` rend `MedicalStageTile`, un `AppointmentItem` rend `CustomAppointmentTile`. `HealthPage` `ref.listen` aussi le nouveau contrôleur pour le garder vivant et afficher ses erreurs.
- `CustomAppointmentTile` : titre, pastille « RDV libre » et pastille « Vaccins » si des injections sont notées, texte de statut, chevron. Tap : feuille d'édition.
- `healthStatusText` est factorisé : la phrase pour `done` / `appointmentPassed` / `scheduled` (avec ou sans praticien) est partagée par les étapes et les RDV libres.
- `CustomAppointmentSheet` (bottom sheet `isScrollControlled`), sections en widgets privés :
  1. Titre (`TextField`, capitalisation phrase, autofocus à la création).
  2. Rendez-vous : date et heure (`showColetteDateTimePicker`, borne basse naissance, borne haute fin de fenêtre calendrier, valeur initiale = maintenant arrondi à l'heure suivante), praticien. Pas de « Retirer le RDV » : la date est obligatoire.
  3. Vaccins : une `StageVaccineRow` par `VaccineCode`, décochée par défaut, sans mention « recommandé » ; puis les lignes « Autre vaccin » (nom, date, marque, lot, bouton retirer) et un bouton « Ajouter un autre vaccin ». Date par défaut d'une injection : date de visite, sinon date du RDV si passée, sinon aujourd'hui.
  4. Visite : `StageVisitFields` (marquer comme faite, date, note).
  Bouton « Enregistrer » inactif pendant l'écriture ou sans profil bébé. En édition, bouton « Supprimer » (texte, couleur `danger`) avec confirmation par dialogue ; la suppression ferme la feuille et retire l'événement du Calendrier à la sync suivante.
- Textes dans `app_fr.arb` : `healthAddAppointment`, `healthChipCustom`, `healthSheetTitle`, `healthSheetOtherVaccine`, `healthSheetAddOtherVaccine`, `healthSheetVaccineName`, `healthDeleteAppointmentTitle`, `healthDeleteAppointmentBody`, `errorMedicalTitleRequired`, `errorMedicalVaccineNameRequired`.

## 5. Erreurs

Repositories en `Either<Failure, T>` via `guard()`. Validation par `ValidateCustomAppointment`, traduite par `failureMessage`. Erreurs de sync calendrier : mécanisme existant (`calendarSyncIssueProvider`), rien de nouveau.

## 6. Tests

- **Domaine** (purs) : `ComputeCustomAppointmentStatus` (trois statuts, borne à `now`) ; `MedicalTimeline.items` (insertion avant la bonne étape, après la dernière, égalité de date, deux RDV libres le même jour, aucun RDV libre = étapes inchangées) et `next` (RDV libre avant une étape non faite, RDV libre fait ignoré) ; `ComputeMedicalTimeline` avec RDV libres ; `ComputeMedicalReminderSnapshot` ignore les RDV libres ; `ReconcileCalendar` (création, mise à jour, suppression d'un RDV libre retiré ou fait, coexistence avec les étapes, doublon) ; `ValidateCustomAppointment` (chaque raison, `trim`, vaccin libre sans nom, vaccin avec code et nom).
- **Données** (`fake_cloud_firestore`) : DTO aller-retour avec vaccins connus et libres, clés absentes, document illisible, vaccin illisible ignoré ; repository (tri, suppression, lecture serveur).
- **Présentation** (`pumpApp`, `mocktail`) : page (bouton « + », RDV libre mêlé à la bonne section, tuile avec pastilles) ; feuille (création avec titre vide refusée, création valide appelle `save` avec l'`id` du `FixedIdGenerator`, édition, ajout d'un vaccin connu et d'un vaccin libre, suppression confirmée, bouton inactif pendant l'écriture) ; contrôleur (validation, écriture, suppression, sync appelée) ; `FirestoreHealthSync` réconcilie aussi les RDV libres et n'écrit rien si leur lecture serveur échoue ; `HealthSyncGate` relance sur émission des RDV libres.
- **Navigation** : `app_router_test` attend cinq destinations, Aujourd'hui au centre, tap sur Santé ouvre `HealthPage` ; `ColetteTabBar` (sélection, callback d'index, bouton central sans libellé mais avec sémantique). `dashboard_page_test` ne trouve plus de carte Santé.
- **Cloud Functions** : aucun changement ; le test d'alignement des libellés reste tel quel.

## 7. Livraison

- Branche `feat/custom-appointments`, worktree `.claude/worktrees/custom-appointments`, partie de `main` (`05c233f`).
- Merge `--no-ff` après validation explicite de Maxence ; pas de push implicite ; pas de redéploiement des Cloud Functions.
- Conflits prévisibles : `app_fr.arb`, `failure.dart`, `failure_message.dart`, `health_page.dart`, `health_sync.dart`, `app_router.dart`, `main_shell.dart`, `dashboard_page.dart`.

## 8. Hors périmètre

Rappel des RDV libres dans le digest du matin. Récurrence. Rattachement d'un RDV libre à une étape du calendrier. Import d'événements créés à la main dans le Calendrier. Pièces jointes (ordonnance, compte rendu).
