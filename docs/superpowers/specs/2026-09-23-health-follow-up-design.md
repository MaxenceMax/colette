# Colette — Suivi médical : examens obligatoires, vaccins et Calendrier iOS

Date : 2026-09-23. Complète la spec v1 (`2026-09-21-colette-v1-design.md`). Sous-projet B du volet santé, après A (mesures de croissance, `2026-09-23-growth-measurements-design.md`, fusionné). Le sous-projet C (fièvre et médicaments) viendra ensuite.

## 1. Problème

Le carnet de santé fixe un calendrier d'examens obligatoires et de vaccins. Les parents veulent :

- voir à tout moment la prochaine étape et savoir si elle est faite, programmée, à prévoir ou en retard ;
- noter le RDV pris et le retrouver dans le **calendrier iCloud partagé** du foyer (Calendrier iOS natif), sans doublon quel que soit l'iPhone qui l'a saisi ;
- cocher chaque injection reçue, avec nom commercial et numéro de lot facultatifs, comme dans le carnet ;
- être prévenus quand une étape approche sans RDV pris.

## 2. Calendrier de référence

Sources (vérifiées le 2026-09-23 dans un navigateur) :

- examens : [service-public.gouv.fr F35490](https://www.service-public.gouv.fr/particuliers/vosdroits/F35490/0) (vérifié le 29 juillet 2026) et [ameli.fr, 20 examens](https://www.ameli.fr/assure/sante/themes/suivi-medical-de-l-enfant-et-de-l-adolescent/enfant-et-adolescent-20-examens-de-suivi-medical) (11 août 2025) : 8 jours (1er certificat), 2e semaine, 1, 2, 3, 4 et 5 mois, 8 mois (2e certificat), 11 mois, 12 mois, 16-18 mois, 23-24 mois (3e certificat), puis un examen par an de 2 à 5 ans ;
- vaccins : [ameli.fr, vaccins obligatoires](https://www.ameli.fr/assure/sante/themes/vaccination/vaccins-obligatoires) (21 mai 2026) et calendrier des vaccinations 2026 : hexavalent et pneumocoque à 2, 4 et 11 mois ; méningocoque B à 3, 5 et 12 mois ; méningocoques ACWY à 6 et 12 mois ; ROR à 12 mois et entre 16 et 18 mois ; rotavirus recommandé.

Le calendrier est une **table de données embarquée** (`lib/features/health/domain/reference/medical_schedule.dart`), comme les tables OMS : pas de donnée de référence dans Firestore. Une étape = une visite rattachée à un âge. Fenêtre `[début, fin)` en âge ; retenue ici : « à N mois » = `[N mois, N+1 mois)`.

| `stageId` | Libellé | Fenêtre | Examen | Vaccins (★ = recommandé, non obligatoire) |
| --- | --- | --- | --- | --- |
| `day8` | Examen des 8 jours | `[0 j, 8 j)` | ✓, certificat | — |
| `week2` | Examen de la 2e semaine | `[8 j, 15 j)` | ✓ | — |
| `m1` | Examen du 1er mois | `[1 m, 2 m)` | ✓ | — |
| `m2` | Examen et vaccins des 2 mois | `[2 m, 3 m)` | ✓ | hexavalent, pneumocoque, rotavirus ★ |
| `m3` | Examen et vaccins des 3 mois | `[3 m, 4 m)` | ✓ | méningocoque B, rotavirus ★ |
| `m4` | Examen et vaccins des 4 mois | `[4 m, 5 m)` | ✓ | hexavalent, pneumocoque, rotavirus ★ (selon le vaccin) |
| `m5` | Examen et vaccins des 5 mois | `[5 m, 6 m)` | ✓ | méningocoque B |
| `m6` | Vaccin des 6 mois | `[6 m, 7 m)` | — | méningocoques ACWY |
| `m8` | Examen des 8 mois | `[8 m, 9 m)` | ✓, certificat | — |
| `m11` | Examen et vaccins des 11 mois | `[11 m, 12 m)` | ✓ | hexavalent, pneumocoque |
| `m12` | Examen et vaccins des 12 mois | `[12 m, 13 m)` | ✓ | ROR, méningocoques ACWY, méningocoque B |
| `m16` | Examen et vaccin des 16-18 mois | `[16 m, 19 m)` | ✓ | ROR (2e dose) |
| `m23` | Examen des 23-24 mois | `[23 m, 25 m)` | ✓, certificat | — |
| `y2` | Examen des 2 ans | `[25 m, 36 m)` | ✓ | — |
| `y3` | Examen des 3 ans | `[36 m, 48 m)` | ✓ | — |

Première version de cette spec corrigée le 2026-09-23 : elle suivait l'ancien calendrier (certificats à 9 et 24 mois, examens à 6, 9 et 13 mois, pas d'examen à 1 et 11 mois). La protection contre le VRS (nirsévimab, souvent donnée à la maternité) et les étapes après 3 ans sont hors périmètre.

Codes de vaccins (`VaccineCode`) : `hexavalent` (DTCaP-Hib-HépB), `pneumococcal`, `menB`, `menACWY`, `mmr` (ROR), `rotavirus`. Chaque vaccin attendu d'une étape porte `recommended: bool`.

Calcul des dates : `birthDate + N mois` avec le jour borné à la fin du mois (31 janvier + 1 mois = 28 ou 29 février) ; `birthDate + N jours` en jours civils.

## 3. Domaine (`lib/features/health/domain`)

| Élément | Rôle |
| --- | --- |
| `MedicalStage` (freezed) | Définition d'une étape : `id`, `window` (`fromAge`, `untilAge` en `AgeOffset` = jours ou mois), `hasExam`, `hasCertificate`, `vaccines: List<ScheduledVaccine>`. |
| `MedicalVisit` (freezed) | État saisi pour une étape : `stageId`, `appointmentAt?`, `practitioner?`, `doneAt?`, `note?`, `vaccines: Map<VaccineCode, GivenVaccine>`, `updatedAt`, `updatedByDeviceId`. |
| `GivenVaccine` (freezed) | `givenAt`, `brand?`, `lot?`. Présent = injection reçue. |
| `MedicalStageStatus` (enum) | `done`, `appointmentPassed` (RDV passé, visite non marquée faite), `scheduled`, `late`, `due`, `upcoming`. |
| `ComputeMedicalStageStatus` (pur) | Pour une étape, sa visite éventuelle, la date de naissance et `now` : `done` si `doneAt` ; sinon `appointmentPassed` si `appointmentAt < now` ; sinon `scheduled` si `appointmentAt` ; sinon `late` si `now ≥ fin de fenêtre` ; sinon `due` si `now ≥ début − 14 jours` ; sinon `upcoming`. Les vaccins recommandés non reçus n'influent jamais sur le statut. |
| `ComputeMedicalTimeline` (pur) | Toutes les étapes avec dates absolues (`dueFrom`, `dueUntil`), statut et visite, triées par âge ; plus `next` = première étape non `done`. |
| `ComputeMedicalReminderSnapshot` (pur) | Les 3 premières étapes non faites et sans RDV : `{stageId, dueFrom, dueUntil, hasAppointment}` ; sert au digest (§6). |
| `ReconcileCalendar` (pur) | Voir §5. |
| `MedicalRepository` | `watchVisits`, `saveVisit` (`set` complet), `deleteVisit`, `saveReminderSnapshot`. |
| `CalendarRepository` | Pont vers EventKit (§5). |

`ValidationReason` gagne `medicalDateBeforeBirth` (RDV antérieur à la naissance) et `medicalDateInFuture` (visite marquée faite dans le futur, tolérance 5 min comme les événements).

## 4. Données

- `households/{code}/medicalVisits/{stageId}` (identifiant = `stageId`, un document par étape touchée) :
  ```
  { appointmentAt?: Timestamp, practitioner?: string, doneAt?: Timestamp, note?: string,
    vaccines?: { [code]: { givenAt: Timestamp, brand?: string, lot?: string } },
    updatedAt: Timestamp, updatedByDeviceId: string }
  ```
  Clés absentes plutôt que `null`. Une visite vidée de tout contenu (plus de RDV, pas faite, aucun vaccin) est supprimée.
- `households/{code}.medicalReminder` (snapshot, même principe que `feedingPlan`) :
  ```
  { stages: [ { stageId, dueFrom: Timestamp, dueUntil: Timestamp, hasAppointment: bool } ], computedAt: Timestamp }
  ```
  Réécrit par le client après toute écriture santé et au démarrage de l'app (provider `medicalReminderSyncProvider`, best-effort, erreurs journalisées).
- `FirestorePaths.medicalVisits`. Règles Firestore inchangées (la règle générique couvre la sous-collection).
- Préférences locales de l'iPhone (`SharedPreferences`) : `health_calendar_id`, `health_calendar_title`.

## 5. Calendrier iOS

### 5.1 Réglage par iPhone

Section « Calendrier » dans Réglages : « Ajouter les RDV santé à : {titre du calendrier} » / « Choisir un calendrier ». Au premier choix : demande d'accès complet, puis liste des calendriers modifiables (titre, couleur, compte). Le choix est local à l'iPhone : les identifiants EventKit diffèrent d'un appareil à l'autre. « Ne plus synchroniser » efface le choix sans toucher aux événements existants.

### 5.2 Pont Swift

`ios/Runner/Calendar/CalendarPlugin.swift`, canal `colette/calendar`, enregistré comme `DocumentsPlugin`. Méthodes :

| Méthode | Entrée | Sortie |
| --- | --- | --- |
| `requestAccess` | — | `granted` / `denied` (`requestFullAccessToEvents` si iOS 17+, sinon `requestAccess(to: .event)`) |
| `listCalendars` | — | `[{id, title, colorHex, source}]`, calendriers `allowsContentModifications` seulement |
| `findEvents` | `calendarId, from, to` | `[{eventId, url, title, start, end, notes, externalId}]` dont l'URL commence par `colette://rdv/` (`externalId` : `calendarItemExternalIdentifier`, l'UID iCloud, identique sur les deux iPhones) |
| `upsertEvent` | `calendarId, eventId?, url, title, start, end, notes, alarms` | `eventId` |
| `deleteEvent` | `calendarId, eventId` | — |

Erreurs remontées en codes : `accessDenied`, `calendarNotFound`, `io`. `Info.plist` : `NSCalendarsFullAccessUsageDescription` et `NSCalendarsUsageDescription` (« Colette ajoute les rendez-vous médicaux de votre bébé au calendrier que vous choisissez. »). `NativeCalendarRepository` côté Dart, `Failure` dédiée `CalendarFailure(reason)`.

### 5.3 Événement

- Titre : libellé de l'étape + « · {prénom} » (« Examen et vaccins des 2 mois · Colette »).
- Début : `appointmentAt` ; fin : +30 min.
- URL : `colette://rdv/{stageId}` (clé de déduplication, identique sur les deux iPhones).
- Notes : praticien s'il est renseigné.
- Alertes : la veille à 18 h (alerte absolue) et 1 h avant.

### 5.4 Réconciliation

`ReconcileCalendar(visits, stages, babyName, events, now) → List<CalendarAction>` (pur, testé) :

- **RDV attendus** : visites avec `début d'hier ≤ appointmentAt < now + 2 ans` et sans `doneAt`. Au-delà de la fenêtre, le RDV est ignoré (il serait de toute façon absent de `findEvents`, donc invisible pour le nettoyage).
- Début, fin et alertes sont calculés sur `appointmentAt` tronqué à la minute (`DateTime(year, month, day, hour, minute)`) : Firestore garde les secondes/microsecondes, EventKit les tronque, la comparaison doit ignorer cet écart.
- Alertes : la veille à 18 h et 1 h avant, en ne gardant que celles postérieures à `now` (pas d'alerte dans le passé).
- **Événements présents** : ceux renvoyés par `findEvents` sur `[début d'hier, now + 2 ans]`, groupés par URL.
- Pour chaque RDV attendu : aucun événement → `create` ; un événement dont début, fin (à la minute) ou titre diffère → `update` ; plusieurs événements → garder celui dont l'`externalId` est le plus petit dans l'ordre lexicographique (les `externalId` nuls passent après, égalité ou absence départagée par `eventId`) — ce critère est identique sur les deux iPhones, contrairement à `eventId` qui est propre à chaque appareil —, mis à jour si besoin, `delete` des autres.
- Chaque événement dont l'URL ne correspond à aucun RDV attendu → `delete`.

`CalendarSyncController` (présentation) lit le calendrier choisi, appelle `findEvents`, calcule les actions et les exécute une par une. Déclenchée après chaque écriture de visite par cet iPhone, au démarrage de l'app et à l'ouverture de la page Santé. Sans calendrier choisi : rien. `calendarNotFound` : choix local effacé, message « Calendrier introuvable, choisis-en un autre ». `accessDenied` : message avec bouton « Ouvrir les Réglages ». Tout autre échec : journalisé (`log(..., name: 'colette')`), jamais bloquant ; Firestore reste la source de vérité.

Limites assumées : si les deux iPhones créent l'événement avant la synchronisation iCloud, un doublon existe jusqu'à la prochaine réconciliation, qui le supprime (déterministe grâce à l'`externalId`, une fois l'UID iCloud répliqué). Un événement plus ancien que `windowStart(now)` (RDV reporté à une date antérieure à la fenêtre lue) n'est jamais relu par `findEvents` ni nettoyé : il reste dans le calendrier.

## 6. Rappels

- **Carte d'accueil « Santé »** (après la carte Poids) : prochaine étape non faite. « Examen et vaccins des 2 mois · à faire entre le 1er et le 30 nov. » (`due` / `upcoming`), « RDV le 3 nov. à 10 h · Dr Martin » (`scheduled`), « RDV du 3 nov. passé · à marquer comme faite » (`appointmentPassed`), « En retard depuis le 1er déc. » en `warning` (`late`). Si la prochaine étape est `upcoming` à plus de 30 jours : une ligne discrète « Prochaine étape : {libellé}, à partir du {date} ». Tap : page Santé.
- **Digest du matin** (`functions/src/morning-digest.ts`) : lit `medicalReminder.stages`. Pour chaque étape avec `hasAppointment = false` et `aujourd'hui (Paris) ≥ dueFrom − 14 jours` : une ligne « RDV à prendre : {libellé} » (ou « En retard : {libellé} » si `aujourd'hui ≥ dueUntil`). Les libellés sont portés par une table `stageId → libellé` dans `functions/src/lib/medical-stages.ts`, alignée sur les `stageId` du client (voir §9). Le digest part s'il y a au moins un soin en attente **ou** une ligne santé ; le corps concatène les soins puis les lignes santé.

## 7. Présentation

- Route `/today/health` (`AppRoutes.health`), page `HealthPage`, imbriquée sous Aujourd'hui comme Croissance, Sommeil et Documents.
- **Page Santé** : sections « En retard », « À faire », « À venir », « Faites » (repliée, avec le nombre). Ligne d'étape : libellé, pastilles « Examen » / « Vaccins » / « Certificat », statut, date (fenêtre, RDV ou date de visite). Tap : feuille d'étape. En-tête : état de la synchronisation calendrier (« Synchronisé avec {calendrier} » ou « Calendrier non configuré »).
- **Feuille d'étape** (bottom sheet, `isScrollControlled`), sections extraites en widgets privés :
  1. Rendez-vous : date et heure (`CupertinoDatePicker`, borne basse = naissance), praticien (texte libre), « Retirer le RDV ».
  2. Vaccins attendus : une ligne par vaccin (nom générique, « recommandé » si ★). Case cochée → champs date (défaut : date de visite, sinon RDV, sinon aujourd'hui), nom commercial, lot.
  3. Visite : date de visite, note, bouton « Marquer comme faite » / « Annuler la visite ».
  Bouton « Enregistrer » : valide, écrit la visite, met à jour le snapshot, lance la réconciliation. Bouton inactif pendant l'écriture (même règle que la feuille de mesure).
- **Réglages** : section « Calendrier » (§5.1), entre « Notifications » et « Apparence ».
- Textes dans `app_fr.arb` (libellés d'étapes, noms de vaccins, statuts, messages calendrier).

## 8. Erreurs

Repositories en `Either<Failure, T>` via `guard()` ; `CalendarFailure(CalendarReason.accessDenied | calendarNotFound | io)` traduite par `failureMessage`. Validation par `ValidateMedicalVisit` (RDV avant la naissance, visite faite dans le futur, date d'injection dans le futur).

## 9. Tests

- **Domaine** (purs) : table du calendrier (identifiants uniques, fenêtres croissantes et non vides, vaccins obligatoires présents aux bons âges) ; `ComputeMedicalStageStatus` (chaque statut, bornes à `début − 14 j`, fin de fenêtre, RDV passé, vaccins recommandés sans effet) ; ajout de mois en fin de mois ; `ComputeMedicalTimeline` (`next`) ; `ComputeMedicalReminderSnapshot` ; `ReconcileCalendar` (création, mise à jour, doublon, suppression d'un RDV retiré, visite faite, calendrier vide, RDV d'hier conservé) ; `ValidateMedicalVisit`.
- **Données** : DTO de visite (`fake_cloud_firestore`, clés absentes, relecture) ; `NativeCalendarRepository` avec un `MethodChannel` simulé (arguments, décodage, codes d'erreur).
- **Présentation** (`pumpApp`, `mocktail`) : carte d'accueil pour chaque statut ; page (sections, repli des faites) ; feuille (RDV, vaccins avec lot, visite faite, bouton inactif pendant l'écriture) ; section Calendrier (choix, accès refusé, calendrier introuvable) ; `CalendarSyncController` exécute les actions calculées.
- **Cloud Functions** : digest avec soins seuls, santé seule, les deux, étape avec RDV (pas de ligne), étape en retard ; table des libellés alignée sur les `stageId` (test Dart qui extrait par expression régulière les clés de `functions/src/lib/medical-stages.ts` et les compare aux `stageId` du calendrier).
- **Simulateur** : un test `integration_test` (`integration_test/calendar_bridge_test.dart`) appelle `NativeCalendarRepository` sur le simulateur iPhone : accès, création d'un calendrier local de test, `upsertEvent`, `findEvents`, mise à jour, `deleteEvent`. Il n'utilise pas Firestore, donc aucun foyer de test en production. La vérification visuelle de l'app complète (clair et sombre) se fait si Maxence accepte de rejoindre son foyer depuis le simulateur.

## 10. Livraison

- Branche `feat/health-follow-up`, worktree `.claude/worktrees/health-follow-up`, partie de `main` (`1463dea`).
- Merge `--no-ff` après validation explicite ; redéploiement des Cloud Functions (`morningDigest`) à faire par Maxence après le merge.
- Conflits prévisibles avec les branches en cours : `app_fr.arb`, `app_router.dart`, `dashboard_page.dart`, `settings_page.dart`, `Info.plist`, `failure.dart`.

## 11. Hors périmètre

RDV libres (maladie, spécialiste) : sous-projet C. Lien direct visite → feuille de mesures de croissance. Étapes après 3 ans, VRS, rattrapages. Import d'événements créés à la main dans le Calendrier. Export PDF du suivi.
