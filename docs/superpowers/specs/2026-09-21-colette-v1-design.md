# Colette v1 — Design

**Date** : 2026-09-21
**Statut** : validé par Maxence (design), en attente de relecture de cette spec

## 1. Contexte et objectif

Colette est une application iOS privée, utilisée par deux parents pour suivre les soins quotidiens de leur nouveau-né. Pas de compte utilisateur, pas d'écran de connexion. Les deux iPhones partagent les mêmes données en temps réel.

Périmètre v1 : soins quotidiens (biberons, couches, Adrigyl, bain, yeux, nez, nombril), tableau de bord du jour, journal chronologique, notifications push.

Hors périmètre v1 : courbes de croissance, export, multi-bébés, mode paysage, Android, web.

## 2. Stack

| Brique | Choix |
| --- | --- |
| Framework | Flutter 3.47 / Dart 3.13, cible iOS uniquement |
| Architecture | Clean Architecture feature-first (domain / data / presentation) |
| État | Riverpod 3 avec codegen (`riverpod_annotation`, `riverpod_generator`), `riverpod_lint` |
| Modèles | `freezed` + `json_serializable` |
| Navigation | `go_router` avec `StatefulShellRoute` (3 onglets) |
| Erreurs | `fpdart` `Either<Failure, T>` + `Failure` sealed |
| Données | Cloud Firestore, persistance hors ligne activée |
| Auth | Firebase Auth anonyme, invisible pour l'utilisateur |
| Push | Firebase Cloud Messaging + Cloud Functions (TypeScript) |
| Local | `shared_preferences` (code foyer, identifiant appareil) |
| Polices | `google_fonts` : Fraunces (titres), DM Sans (corps) |
| i18n | `flutter_localizations` + gen-l10n, `app_fr.arb` uniquement |
| Tests | `flutter_test`, `mocktail`, `fake_cloud_firestore` |

Les dossiers `android/`, `web/`, `macos/`, `linux/`, `windows/` sont supprimés du projet.

## 3. Architecture

```
lib/
  main.dart                         initialise Firebase, ProviderScope, runApp
  app/
    colette_app.dart                MaterialApp.router, thèmes light/dark, locale fr
    router/app_router.dart          routes + shell 3 onglets
  core/
    theme/
      app_colors.dart               enum AppColors(light, dark) + context.appColor()
      design_tokens.dart            AppSpacing, AppRadius, AppSize, AppFontSize, AppDuration, AppOpacity, AppElevation
      text_styles.dart              enum ColetteTextStyle + Theme.of(context).coletteTextStyles
      theme_service.dart            ThemeData light/dark construit depuis les tokens
    result/
      failure.dart                  sealed Failure : Network, NotFound, Validation, Unknown
    clock/
      clock_provider.dart           DateTime.now() injectable
    firebase/
      firestore_paths.dart          chemins de collections centralisés
  features/
    household/                      foyer : création, jonction par code, appareil courant
    baby/                           profil bébé, pesées, réglages des soins
    events/                         événements de soin : CRUD, timeline paginée, formulaire
    dashboard/                      « à faire aujourd'hui » + plan biberons (calcul OMS)
    notifications/                  token FCM, permissions, préférences de notification
  shared/
    ui/widgets/                     ColetteCardSurface, SectionHeader, CareChip, EmptyState, OfflineBanner
    domain/                         entités partagées entre features (CareType)
  l10n/
    app_fr.arb
functions/                          Cloud Functions TypeScript (voir §7)
firestore.rules
firebase.json
```

Chaque feature contient :

```
features/{name}/
  domain/
    entities/                       @freezed
    repositories/                   interfaces abstraites
    use_cases/                      classes pures, une méthode call()
  data/
    dtos/                           @freezed + fromJson/toJson, conversion depuis/vers entité
    data_sources/                   accès Firestore ou shared_preferences
    repositories/                   implémentations des interfaces du domaine
  presentation/
    providers/                      @riverpod : repositories, use cases, notifiers
    pages/
    widgets/
```

Règles de dépendance : `domain` n'importe ni `data` ni `presentation` ni Flutter. `presentation` n'importe jamais `data` (l'injection se fait via providers dans `presentation/providers/`). Aucune dépendance directe entre features : les données partagées passent par `shared/domain/`.

## 4. Design system

Mécanique identique à Calpin, renommée Colette. Aucune valeur de style en dur dans les pages et widgets : tout passe par les tokens.

### 4.1 Couleurs (`AppColors`, light / dark)

| Token | Light | Dark | Usage |
| --- | --- | --- | --- |
| primary | #A8573F | #D08A6F | cannelle : actions, accents, onglet actif |
| onPrimary | #FFFFFF | #1C1514 | texte sur primary |
| primaryContainer | #F3E2DA | #3A2A24 | poudre : lignes de tâches, fonds légers |
| secondary | #E9B9A8 | #86584B | rose poudré : compteurs, badges |
| onSecondary | #5C2A1B | #F7E6E0 | texte sur secondary |
| accent | #D9A441 | #E4B85C | miel : fonds et décorations uniquement, jamais en texte |
| pageBackground | #FBF5EF | #1C1514 | lin : fond des écrans |
| surface | #FFFFFF | #2B2220 | cartes |
| surfaceContainer | #F6EBE4 | #342925 | champs, zones secondaires |
| onSurface | #2E2320 | #F1E6E0 | texte principal |
| textSecondary | #756059 | #B8A39B | dates, labels (assombri pour ≥ 4,5 sur primaryContainer) |
| border | #EAD9CF | #4A3A34 | bordures fines |
| success | #57795D | #9DBBA2 | eucalyptus : fait, validé |
| warning | #8F6412 | #E4B85C | en retard |
| error | #B4503B | #E27A62 | erreurs (assombri pour ≥ 4,5 sur pageBackground) |
| categoryFeeding | #A8573F | #D08A6F | biberon |
| categoryDiaper | #8F6412 | #E4B85C | pipi, caca, couche |
| categoryCare | #57795D | #9DBBA2 | yeux, nez, nombril, Adrigyl |
| categoryBath | #A8624F | #C98A79 | bain |
| shadow | #000000 | #FFFFFF | ombres |

Accès : `context.appColor(AppColors.primary)`. Une couleur manquante s'ajoute dans l'enum avec ses deux valeurs avant tout usage.

### 4.2 Tokens dimensionnels

Mêmes enums et extensions que Calpin : `AppSpacing` (xxs 2 → xxxl 64, `.all`, `.horizontal`, `.verticalSpace`…), `AppRadius` (xs 4 → xxl 24, round 999, `.circular`, `.topOnly`…), `AppSize` (nano 8 → massive 96), `AppFontSize`, `AppDuration`, `AppOpacity`, `AppElevation`.

### 4.3 Typographie (`ColetteTextStyle`)

| Style | Police | Taille / graisse |
| --- | --- | --- |
| displayTitle | Fraunces | 32 / 600 |
| heading1 | Fraunces | 26 / 600 |
| heading2 | Fraunces | 20 / 600 |
| heading3 | Fraunces | 17 / 600 |
| numberLarge | Fraunces | 40 / 600 |
| numberMedium | Fraunces | 24 / 600 |
| bodyLarge | DM Sans | 16 / 400 |
| body | DM Sans | 14 / 400 |
| bodyMedium | DM Sans | 14 / 500 |
| label | DM Sans | 13 / 500 |
| small | DM Sans | 12 / 400 |
| overline | DM Sans | 11 / 500, espacement 0,06 em |

Accès : `Theme.of(context).coletteTextStyles.heading1`. Les couleurs de texte se posent par `copyWith(color: context.appColor(...))`.

### 4.4 Composants partagés

- `ColetteCardSurface` : fond surface, bordure `border`, rayon `AppRadius.lg`, extension `.withColetteCardSurface()`.
- `SectionHeader` : titre Fraunces + action optionnelle à droite.
- `CareChip` : puce à cocher avec icône et couleur de catégorie, utilisée dans le formulaire.
- `CareTaskRow` : ligne « à faire » du dashboard (icône, libellé, statut, tap = créer l'événement).
- `EmptyState`, `OfflineBanner`. Les feuilles modales utilisent `showModalBottomSheet` avec le `BottomSheetThemeData` du thème (fond lin, coins arrondis, poignée).

### 4.5 Thème

`ThemeService.getThemeData(Brightness)` construit `ColorScheme`, `TextTheme`, `AppBarTheme`, boutons, champs, `NavigationBarTheme`, `BottomSheetTheme` depuis les tokens. `ThemeMode.system` par défaut, sans réglage utilisateur en v1.

## 5. Données Firestore

```
households/{code}
  createdAt: Timestamp
  baby:
    name: string
    birthDate: Timestamp
    cordFallenAt: Timestamp | null
    careSettings:                     une map par soin, voir 2026-09-24-care-frequency-design.md
      adrigyl:       { timesPerDay: 1, everyDays: 1, enabled: true }
      eyeCare:       { timesPerDay: 1, everyDays: 1, enabled: true }
      noseCare:      { timesPerDay: 1, everyDays: 1, enabled: true }
      umbilicalCare: { timesPerDay: 3, everyDays: 1, enabled: true }   enabled passe à false quand cordFallenAt est renseigné, à true quand elle est effacée
      bath:          { timesPerDay: 1, everyDays: 2, enabled: true }
      feedsPerDay: 8
  feedingPlan:                        écrit par le client à chaque sauvegarde d'événement biberon
    nextBottleAt: Timestamp           heure centrale du prochain biberon
    windowStartAt: Timestamp          début de la fourchette (absent avant la fourchette, voir 2026-09-23-bottle-window-design.md)
    windowEndAt: Timestamp            fin de la fourchette
    suggestedMl: number
    computedAt: Timestamp
  lastBottleNotifiedFor: Timestamp | null   écrit par la fonction de rappel biberon
  diaperStock:                        stock de couches, renseigné depuis les Réglages
    count: number                     couches comptées à countedAt
    countedAt: Timestamp              restant = count − changes dont startAt ≥ countedAt
    alertThreshold: 10                0 = alerte désactivée
    lastPackSize: 44
  medicalReminder:                    écrit par le client après chaque écriture santé ; lu par le digest du matin, détail dans 2026-09-23-health-follow-up-design.md
    stages: [ { stageId, dueFrom: Timestamp, dueUntil: Timestamp, hasAppointment: bool } ]
    computedAt: Timestamp

households/{code}/medicalVisits/{stageId}   examens et vaccins, un document par étape du calendrier ; détail dans 2026-09-23-health-follow-up-design.md

households/{code}/weights/{id}      mesures de croissance (poids, taille, périmètre crânien) ; nom historique, détail dans 2026-09-23-growth-measurements-design.md
  measuredAt: Timestamp
  grams: number | null               au moins une des trois valeurs présente
  lengthMm: number | null
  headCircumferenceMm: number | null

households/{code}/events/{id}
  startAt: Timestamp
  endAt: Timestamp
  pee: bool
  poop: bool
  diaperChange: bool
  adrigyl: bool
  bath: bool
  eyeCare: bool
  noseCare: bool
  umbilicalCare: bool
  bottleMl: number | null
  note: string | null
  createdByDeviceId: string
  createdAt: Timestamp
  updatedAt: Timestamp

households/{code}/devices/{deviceId}
  fcmToken: string
  label: string                       « iPhone de Maxence », saisi à la jonction
  notifyOnOthersEvents: true
  notifyBottleReminder: true
  notifyMorningDigest: true
  morningDigestHour: 8
  lastDigestSentOn: string | null     « 2026-09-22 » (Paris), écrit par le digest du matin
  updatedAt: Timestamp
```

Le `code` du foyer est une chaîne de 8 caractères alphanumériques majuscules sans ambiguïté (pas de O/0, I/1), générée côté client, et sert d'identifiant de document. L'`deviceId` est un UUID généré au premier lancement et conservé dans `shared_preferences`.

### 5.1 Règles de sécurité

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Le document foyer est atteignable par son code, jamais énumérable
    // (aucun `read`/`list` accordé ici), et créé seulement avec un code au
    // format généré par l'app (8 caractères, alphabet sans O/0 ni I/1).
    match /households/{code} {
      allow get: if request.auth != null;
      allow create: if request.auth != null && code.matches('^[A-HJ-NP-Z2-9]{8}$');
      allow update: if request.auth != null;
      allow delete: if false;
    }
    // Sous-collections : events, weights, devices.
    match /households/{code}/{collection}/{docId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

L'auth anonyme est déclenchée silencieusement au démarrage. Le client ne liste jamais `households` (il accède toujours à `.doc(code)`), et les Cloud Functions passent par l'Admin SDK. Les fonctions planifiées tournent avec `maxInstances: 1` pour qu'une double livraison Pub/Sub ne produise pas de double envoi. La confidentialité repose sur le caractère non devinable du code (alphabet de 32 caractères sans O/0 ni I/1, soit 32^8 ≈ 1,1 × 10^12 combinaisons) et sur l'exigence d'une session Firebase signée.

### 5.2 Hors ligne

Persistance Firestore activée. Les écritures en file d'attente partent à la reconnexion. Un `OfflineBanner` s'affiche quand `connectivity` indique une absence de réseau, uniquement informatif.

## 6. Fonctionnel

### 6.1 Premier lancement (feature `household`)

Écran d'accueil sans foyer : deux boutons, « Créer notre foyer » et « Rejoindre avec un code ». Création : saisie du prénom du bébé, de sa date de naissance et du nom de l'appareil, génération du code, écriture du document, stockage local du code. Jonction : saisie du code et du nom de l'appareil ; si le document existe, stockage local et enregistrement de l'appareil ; sinon message « Code inconnu ». Ensuite l'app démarre directement sur le dashboard à chaque lancement.

### 6.2 Onglet « Aujourd'hui » (feature `dashboard`)

Contenu, de haut en bas :

1. En-tête : date du jour, « {prénom} a {âge} » (jours jusqu'à 2 semaines, puis semaines jusqu'à 2 mois, puis mois).
2. Carte d'alerte « Plus que N couches », uniquement si le stock restant est strictement inférieur au seuil (voir `2026-09-22-diaper-stock-design.md`). Tap : ouvre les Réglages.
3. Carte « Prochain biberon » : quantité suggérée en ml, fourchette (« entre 7h45 et 8h35 », « maintenant, jusqu'à 8h35 »), texte « X sur Y donnés · A / B ml », barre de progression. Si aucune pesée n'est enregistrée : mention « Repères par âge, ajoute une pesée pour un calcul au poids ». Tap : ouvre le formulaire avec la quantité suggérée préremplie. Bouton horloge : feuille « Prochaines 24 h » (fourchettes et quantités prévues, voir `2026-09-23-bottle-window-design.md`).
4. Section « Reste à faire » : une `CareTaskRow` par soin attendu non fait. Tap : crée immédiatement un événement pré-rempli (heure = maintenant, soin coché) puis affiche une snackbar « Enregistré » avec « Annuler ». Les soins faits passent en bas, grisés, avec l'heure.
5. Compteurs du jour : couches, pipis, cacas.

Soins attendus (depuis `careSettings`, règle commune aux cinq soins, voir `2026-09-24-care-frequency-design.md`) :

| Cas | Accueil |
| --- | --- |
| Suivi coupé (`enabled: false`) | Jamais listé, même fait aujourd'hui. |
| `timesPerDay` par jour (`everyDays` = 1) | Toujours listé, cible `timesPerDay`. |
| Tous les `everyDays` jours, dernier fait il y a moins de `everyDays` jours civils | Absent (bain lundi, tous les 2 jours : attendu mercredi). |
| Tous les `everyDays` jours, dû ou jamais fait | Listé, à faire. |
| Fait aujourd'hui, quelle que soit la fréquence | Listé, grisé « fait ». |

Le jour civil va de 00:00 à 23:59 heure locale de l'appareil.

Use case `ComputeDailyCareStatus(événements des 7 derniers jours, careSettings, now) → List<CareTask>`. Pur, testé.

### 6.3 Plan biberons (use case `ComputeFeedingPlan`)

Entrées : `birthDate`, dernière pesée (`grams`, peut être absente), `feedsPerDay`, biberons du jour civil (liste `{startAt, ml}`), dernier biberon toutes dates confondues, `now`.

Cible journalière selon l'OMS (*Infant and young child feeding: model chapter*, session 6 et 8) :

- Jour de vie `d` (jour de naissance = 1) : `mlParKg = min(150, 60 + 20 × (d − 1))`, soit 60, 80, 100, 120, 140 puis 150 à partir du jour 6.
- `dailyTargetMl = mlParKg × poidsKg`, arrondi à 10 ml.
- Sans pesée, repli sur une table par âge qui fournit uniquement `dailyTargetMl`, affichée comme indicative. `feedsPerDay` vient toujours des réglages (8 par défaut), pour l'intervalle comme pour la suggestion :

| Âge | `dailyTargetMl` (repère) |
| --- | --- |
| jours 1 à 5 | 240, 320, 400, 440, 480 |
| jour 6 – 1 mois | 480 |
| 1 – 2 mois | 630 |
| 2 – 4 mois | 720 |
| 4 – 6 mois | 900 |
| 6 mois et plus | 900 |

Sorties :

- `intervalle = 24 h / feedsPerDay` (3 h pour 8 prises).
- `nextBottleAt = dernierBiberon.startAt + intervalle`, ou `now` si aucun biberon.
- Fourchette : `nextBottleAt ± round(0,15 × intervalle)`, bornes arrondies aux 5 min ; réduite à `now` sans biberon. Après `windowEnd`, le dashboard affiche « en retard de N min » (compté depuis `windowEnd`) en `warning`.
- `bottlesGiven = nombre de biberons du jour`, `bottlesRemaining = max(0, feedsPerDay − bottlesGiven)`.
- `givenMl = somme des ml du jour`, `remainingMl = max(0, dailyTargetMl − givenMl)`.
- `suggestedMl = bottlesRemaining > 0 ? arrondi10(remainingMl / bottlesRemaining) : arrondi10(dailyTargetMl / feedsPerDay)`, borné entre 30 ml et 240 ml.

La carte affiche en complément le nombre de biberons et les ml donnés sur les dernières 24 heures glissantes (« 7 biberons · 410 ml sur les dernières 24 h »), sans effet sur le plan ni sur les Cloud Functions. Le jour civil reste la seule règle de découpage ; voir `2026-09-22-rolling-intake-design.md`.

La table par âge est portée par l'enum `FeedingAgeBand`, source unique. Une cible journalière ajustée (`careSettings.dailyTargetMl`, `null` = OMS, bornée 100 à 1500 ml) remplace la cible OMS dans le calcul ; la carte affiche alors « Cible ajustée à X ml · OMS : Y ml ». Une feuille « Repères OMS », ouverte par une icône info sur la carte, montre la table par âge, la règle ml/kg, la ligne du jour et permet d'ajuster la cible. Le snapshot `feedingPlan` garde la même forme ; voir `2026-09-22-oms-feeding-reference-design.md`.

À chaque création, modification ou suppression d'un événement contenant un biberon, et à chaque ajout ou suppression de pesée ou changement des réglages de soins, le client recalcule et écrit `feedingPlan` dans le document du foyer (même batch d'écriture), pour que la fonction de rappel n'ait pas à réimplémenter la règle.

### 6.4 Onglet « Journal » (feature `events`)

Liste chronologique inverse groupée par jour civil, en-têtes de jour collants (« Aujourd'hui », « Hier », puis « lundi 15 septembre »). Chaque ligne : heure de début (et de fin si différente), icônes des soins cochés avec couleurs de catégorie, quantité du biberon, début de la note.

Pagination : un `StreamProvider` Firestore sur `events` trié par `startAt` décroissant, avec une `limit` qui commence à 30 et augmente de 30 quand l'utilisateur atteint le bas de la liste. Une seule requête temps réel couvre donc les nouveautés de l'autre iPhone et le chargement des pages. Indicateur de chargement en bas tant que la dernière page retournée est pleine.

Actions : tap sur une ligne → formulaire en édition ; glisser vers la gauche → suppression avec confirmation ; bouton flottant « + » → formulaire en création.

### 6.5 Formulaire d'événement

Présenté en bottom sheet modale (`showModalBottomSheet`, hauteur au contenu, `isScrollControlled`, insets clavier gérés). Champs :

- Heure de début et heure de fin : préremplies à `now` à l'ouverture, modifiables par `CupertinoDatePicker` (date + heure). Validation : fin ≥ début, début ≤ maintenant + 5 min.
- Puces `CareChip` : pipi, caca, changement de couche, Adrigyl, bain, soin des yeux, soin du nez, soin du nombril (masquée si le suivi du nombril est coupé).
- Biberon : interrupteur « Biberon » qui révèle un stepper ml (pas de 10, bornes 10 – 300) et des raccourcis 60 / 90 / 120 / 150 / 180 / 210. Prérempli avec `suggestedMl` quand ouvert depuis la carte biberon.
- Note libre, une ligne extensible.
- Bouton « Enregistrer ». Désactivé tant qu'aucune puce n'est cochée et qu'aucun biberon n'est renseigné.

Use case `ValidateCareEvent` pur, testé : refuse un événement vide, une fin avant le début, un biberon hors bornes.

### 6.6 Onglet « Réglages » (features `baby`, `household`, `notifications`)

Sections :

- Bébé : prénom, date de naissance, date de chute du cordon (renseigner cette date coupe le suivi du nombril, l'effacer le rallume).
- Mesures : liste des mesures de croissance (date + poids, taille, périmètre crânien facultatifs), ajout, modification, suppression. La plus récente qui contient un poids sert au calcul. Détail dans `2026-09-23-growth-measurements-design.md`.
- Soins attendus : une ligne par soin (Adrigyl, yeux, nez, nombril, bain) avec un interrupteur « suivi » et une fréquence réglable de « N fois par jour » à « tous les 7 jours » ; prises de biberon / jour.
- Couches : stock restant, « Recompter », « + paquet », seuil d'alerte (0 à 30, 0 = désactivé).
- Notifications de cet appareil : événements ajoutés par l'autre, rappel biberon, digest du matin avec son heure. Demande de permission iOS au premier passage à « activé ».
- Foyer : code affiché en grand avec bouton copier, nom de l'appareil, bouton « Quitter ce foyer » (avec confirmation : supprime `devices/{deviceId}` du foyer, avec un délai maximal de 5 s, puis efface le code local ; le foyer est quitté même si la suppression échoue, l'écriture restant en file Firestore).

## 7. Notifications push (Cloud Functions)

Dossier `functions/` TypeScript, Firebase Functions v2, région `europe-west1`, fuseau `Europe/Paris`. Prérequis : plan Blaze, clé APNs (.p8) déposée dans Firebase, capacités *Push Notifications* et *Background Modes → Remote notifications* activées dans Xcode, compte Apple Developer.

| Fonction | Déclencheur | Comportement |
| --- | --- | --- |
| `onEventCreated` | Firestore `onDocumentCreated` sur `households/{code}/events/{id}` | Envoie un push à chaque appareil du foyer dont `deviceId ≠ createdByDeviceId` et `notifyOnOthersEvents` est vrai ; sans `createdByDeviceId`, personne n'est notifié. Titre : « {label appareil} a ajouté un événement ». Corps : résumé (ex. « Biberon 120 ml · Couche · Adrigyl à 14h32 »). |
| `bottleReminder` | `onSchedule('every 5 minutes')` | Pour chaque foyer dont `feedingPlan` porte une fourchette : rappel dû si `windowStartAt ≤ now ≤ windowEndAt`, `lastBottleNotifiedFor ≠ nextBottleAt` et `computedAt < windowStartAt` (un plan calculé fourchette déjà ouverte, sans biberon enregistré ou avec un dernier biberon trop ancien, ne déclenche rien) : push « Biberon possible dès maintenant · Environ {suggestedMl} ml, d'ici {windowEnd} » aux appareils avec `notifyBottleReminder`. Sans fourchette (snapshot d'une version antérieure de l'app) : ancienne règle, `nextBottleAt − 10 min ≤ now ≤ nextBottleAt + 15 min` et `computedAt < nextBottleAt`, push « Biberon dans 10 min ». `lastBottleNotifiedFor` n'est écrit que si au moins un push est parti ou si aucun appareil n'est abonné ; sinon le tick suivant réessaie, dans la limite de la fenêtre. Chaque foyer est traité dans son propre `try/catch`. |
| `morningDigest` | `onSchedule('every 60 minutes')` | Pour chaque appareil dont `morningDigestHour` correspond à l'heure Europe/Paris la plus proche de l'exécution, `notifyMorningDigest` est vrai et `lastDigestSentOn` ≠ la date du jour (Paris) : calcule les soins attendus non faits ce jour, sur les événements des 7 derniers jours civils Paris `[minuit − 6 j, minuit + 1 j)` (même règle que §6.2, réimplémentée en TypeScript avec ses tests) et envoie « Aujourd'hui pour {prénom} : Adrigyl, soin des yeux, bain », puis écrit `lastDigestSentOn`. Rien n'est envoyé s'il n'y a ni soin en attente ni RDV santé à prendre (lignes « RDV à prendre » / « En retard » lues dans `medicalReminder`, voir `2026-09-23-health-follow-up-design.md`), ou si le foyer n'a pas de profil bébé. Chaque foyer est traité dans son propre `try/catch`. |

Le tap sur une notification ouvre le dashboard (événement, digest) ou le formulaire biberon prérempli (rappel).

Côté client (feature `notifications`) : récupération et rafraîchissement du token FCM, écriture dans `devices/{deviceId}`, gestion du tap sur notification via `go_router`. Les tokens invalides renvoyés par FCM sont supprimés par les fonctions (échec ignoré si l'appareil a déjà quitté le foyer).

Volume attendu : quelques dizaines de pushs par jour, 8 640 exécutions du cron biberon et 720 du digest par mois, très en dessous des quotas gratuits. Une alerte budget à 1 € est recommandée sur le projet.

## 8. Gestion des erreurs

- Repositories et use cases renvoient `Either<Failure, T>`. `Failure` est une classe sealed : `NetworkFailure`, `NotFoundFailure`, `ValidationFailure(reason)` (enum `ValidationReason`, traduit par la présentation), `UnknownFailure(error, stackTrace)`.
- Les data sources laissent remonter les exceptions Firebase ; les repositories les convertissent en `Failure`.
- Les notifiers Riverpod exposent `AsyncValue` ; l'UI utilise `switch` sur `AsyncData` / `AsyncLoading` / `AsyncError`.
- Échec d'écriture : snackbar avec le message de l'échec (`failureMessage`), sans bouton « Réessayer » : l'utilisateur ré-appuie sur l'action, le formulaire ou la bascule ayant conservé sa saisie (les bascules et compteurs optimistes reviennent en arrière). Aucun `print`, aucun catch vide ; les erreurs inattendues passent par `dart:developer log`.

## 9. Tests

- Domaine (TDD, cible 90 %) : `ComputeFeedingPlan` (montée progressive, 150 ml/kg, repli par âge, retard, bornes de suggestion), `ComputeDailyCareStatus` (fréquences N par jour et tous les N jours, suivi coupé), `ValidateCareEvent`, génération du code foyer.
- Data : repositories avec `fake_cloud_firestore` (CRUD événements, pagination par limite, pesées, appareils).
- Présentation : widgets dashboard, formulaire et timeline avec `ProviderScope(overrides: [...])` ; vérification des états vide, chargement, erreur.
- Functions : tests unitaires de la logique du digest et du résumé d'événement avec Vitest.

## 10. Règles projet (CLAUDE.md)

Le fichier `CLAUDE.md` du projet reprend les règles de Calpin adaptées : Clean Architecture feature-first, Riverpod codegen obligatoire (jamais `setState` pour de la logique métier, jamais Bloc ni Provider), design tokens obligatoires, `const` et découpage des widgets, `dispose` des controllers, strings via l10n, `Either` pour les erreurs, iOS uniquement, dot shorthand et `switch` Dart 3, commentaires `///` sur les classes publiques, widgets de moins de 300 lignes.

## 11. Prérequis à fournir par Maxence

1. Projet Firebase créé, plan Blaze activé, alerte budget posée.
2. `flutterfire configure` exécuté pour iOS (génère `lib/firebase_options.dart` et `ios/Runner/GoogleService-Info.plist`).
3. Clé APNs déposée dans Firebase ; capacités push activées dans Xcode ; identifiant de bundle choisi.
4. Firebase CLI installée pour déployer les règles et les fonctions.

## 12. Sources

- OMS, *Infant and young child feeding: model chapter for textbooks for medical students and allied health professionals*, 2009, session 6 (relactation : 150 ml/kg/jour en 6 à 12 prises) et session 8 (alimentation de substitution : 150 ml/kg/jour en 8 prises, 60 ml/kg le premier jour puis +20 ml/kg/jour). https://www.who.int/publications/i/item/9789241597494
- Repères par âge : tables usuelles des laits infantiles et pédiatres français (indicatifs, non normatifs).
