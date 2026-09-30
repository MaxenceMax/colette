# Partage de photos aux proches — design

Date : 2026-09-30.

## Objectif

Penser à envoyer des nouvelles du bébé aux proches, et le faire vite :

1. des **listes de diffusion** (ex. « Grands-parents », « Amis ») composées de contacts de l'iPhone ;
2. un **envoi** : prendre une photo ou en choisir plusieurs dans la galerie, puis envoyer **un message par personne** de la liste, avec les photos et un même texte facultatif ;
3. une **notification quotidienne** à une heure aléatoire entre 8 h et 21 h, qui rappelle d'envoyer une photo.

## Décisions

- **Envoi par feuilles Messages successives** : iOS interdit l'envoi de SMS sans action de l'utilisateur. Pour chaque personne, l'app ouvre `MFMessageComposeViewController` pré-rempli (un seul destinataire, photos jointes, texte) ; l'utilisateur appuie sur « Envoyer », la feuille suivante s'ouvre. Messages choisit iMessage ou MMS.
- **Même texte pour toute la liste** : un seul champ facultatif, vide par défaut, saisi avant l'envoi ; il part à l'identique à chaque personne. Pas de texte par personne ni par liste. La feuille Messages reste modifiable par iOS : une retouche n'affecte que ce destinataire.
- **Données locales à chaque iPhone** : listes, date du dernier envoi et interrupteur de la notification sont dans `shared_preferences`. Rien dans Firestore, chaque parent a ses propres listes.
- **Contacts via le sélecteur d'Apple** (`CNContactPickerViewController`, propriété `phoneNumbers`) : aucune autorisation d'accès au répertoire. Si le contact a plusieurs numéros, le sélecteur fait choisir. Pas de saisie manuelle.
- **Plusieurs photos par envoi** : galerie via `PHPickerViewController` (sélection multiple, aucune autorisation photothèque), appareil photo via `UIImagePickerController` (une photo). Toutes les photos partent dans chaque message.
- **Notification locale**, comme celles du minuteur de biberon (`UNUserNotificationCenter`), pas de Cloud Function, pas d'app Rappels.
- **Pas de package** : canal natif `colette/photo-sharing` (`PhotoSharingPlugin` + `PhotoSharingPresenter`), sur le modèle de `DocumentsPlugin` / `DocumentsPresenter`.
- **Accès** : carte « Photos » sur Aujourd'hui (comme `DocumentsCard`), page `/today/photos`. La barre d'onglets ne change pas.
- **Hors périmètre** : partage des listes avec l'autre parent, texte par personne, historique des envois, choix de la plage horaire, envoi groupé (un seul fil à plusieurs).

## Domaine

`lib/features/photo_sharing/domain/`

- `entities/recipient.dart` (freezed) : `Recipient({required String name, required String phone})`.
- `entities/broadcast_list.dart` (freezed) : `BroadcastList({required String id, required String name, required List<Recipient> recipients})`.
- `entities/send_report.dart` (freezed) : `SendReport({required int sent, required int cancelled, required int failed})`, getter `anySent` (`sent > 0`).
- `repositories/photo_sharing_repository.dart` :
  - `loadLists()` → `Either<Failure, List<BroadcastList>>` (liste vide si absent) ;
  - `saveLists(List<BroadcastList>)` → `Either<Failure, Unit>` ;
  - `loadLastSentAt()` → `Either<Failure, DateTime?>` ;
  - `saveLastSentAt(DateTime)` → `Either<Failure, Unit>` ;
  - `loadReminderEnabled()` → `Either<Failure, bool>` (vrai par défaut) ;
  - `saveReminderEnabled(bool)` → `Either<Failure, Unit>`.
- `use_cases/photo_reminder_schedule.dart` (pur Dart) :
  - constantes `photoReminderStartHour = 8`, `photoReminderEndHour = 21`, `photoReminderDays = 14` ;
  - `List<DateTime> planPhotoReminders({required DateTime now, required DateTime? lastSentAt, Random Function(int seed) randomForDay = Random.new})` : pour chacun des 14 jours à partir d'aujourd'hui (heure locale), une date tirée uniformément à la minute dans `[8:00, 21:00[`. Le jour courant est exclu si `lastSentAt` tombe aujourd'hui ; toute date déjà passée (`≤ now`) est exclue.
  - Le tirage d'un jour ne dépend que du jour : `randomForDay(année * 10000 + mois * 100 + jour)`. Replanifier le même jour redonne la même heure, donc une notification ne « saute » pas à chaque ouverture de l'app. Les tests injectent leur propre fabrique.
  - Sans ouverture de l'app pendant 14 jours, les notifications s'arrêtent ; elles reprennent à l'ouverture suivante.

## Data

`lib/features/photo_sharing/data/`

- `dtos/broadcast_list_dto.dart` : `toJson` / `fromJson` (liste JSON, destinataires imbriqués). Un JSON invalide lève une exception convertie par `guard()`.
- `shared_prefs_photo_sharing_repository.dart` : clés `photo_sharing.lists` (JSON), `photo_sharing.last_sent_at` (millisecondes epoch UTC), `photo_sharing.reminder_enabled` (bool).
- Provider `photoSharingRepositoryProvider` (keepAlive).

## Pont natif

Comme Documents : interface `PhotoSharingSystem` dans `lib/features/photo_sharing/domain/repositories/photo_sharing_system.dart`, implémentation `NativePhotoSharingSystem` dans `data/native_photo_sharing_system.dart` (canal `colette/photo-sharing`), provider `photoSharingSystemProvider` (keepAlive). Les codes d'erreur du canal deviennent `PhotoSharingFailure(PhotoSharingReason)` (`messagesUnavailable`, `cameraUnavailable`, `busy`, `io`, ajoutés dans `core/result/failure.dart` et `failureMessage`) ; toute autre exception devient `UnknownFailure`. Une annulation par l'utilisateur n'est pas une erreur : `null` ou liste vide.

| Méthode | Arguments | Retour Dart |
|---|---|---|
| `pickContact` | — | `Either<Failure, Recipient?>` |
| `takePhoto` | — | `Either<Failure, List<String>>` (0 ou 1 chemin) |
| `pickPhotos` | — | `Either<Failure, List<String>>` (0 à 10) |
| `sendMessages` | `phones`, `photoPaths`, `body` | `Either<Failure, SendReport>` (`messagesUnavailable` si `canSendText()` est faux) |
| `discardPhotos` | `photoPaths` | `Future<void>`, échec logué |
| `syncReminders` | `dates` (millisecondes epoch), `title`, `body` | `Future<void>`, échec logué |
| `takePendingRoute` | — | `Future<String?>`, échec logué |
| `pendingRouteSignals` | (Swift → Dart : `routePending`) | `Stream<void>` |

Côté Swift (`ios/Runner/PhotoSharing/`) :

- **Photos** : chaque image est réencodée en JPEG (qualité 0,8, grand côté ≤ 2048 px) dans `tmp/photo-sharing/<uuid>.jpg`. `discardPhotos` les supprime ; le dossier est vidé au lancement du plugin.
- **Envoi** : `sendMessages` présente une `MFMessageComposeViewController` par destinataire, l'une après l'autre (la suivante après la fermeture de la précédente). Chaque feuille : `recipients = [phone]`, `body`, `addAttachmentData` pour chaque photo (`public.jpeg`). Le résultat de chaque feuille (`.sent`, `.cancelled`, `.failed`) est compté ; une annulation passe à la personne suivante. Le résultat global n'est rendu qu'après la dernière feuille.
- **Exclusivité** : un seul appel de présentation à la fois (`pickContact`, `takePhoto`, `pickPhotos`, `sendMessages`), comme `exclusive` dans `DocumentsPlugin` ; un appel concurrent échoue avec `busy`.
- **Notifications** : `syncReminders` retire les identifiants `photo-reminder.YYYY-MM-DD` de la veille à J+15 (retrait synchrone, donc deux synchronisations rapprochées restent dans l'ordre), puis programme une `UNCalendarNotificationTrigger` (non répétée) par date, son par défaut. Liste vide : tout est retiré. L'autorisation est celle déjà demandée pour FCM ; rien n'est redemandé.
- **Appui sur la notification** : `AppDelegate.userNotificationCenter(_:didReceive:)` repère le préfixe `photo-reminder.`, mémorise la route `/today/photos` dans le plugin et appelle `invokeMethod("routePending")` sur le canal (sans effet si Flutter n'écoute pas encore). `takePendingRoute` rend et efface la route mémorisée : appelé au démarrage (lancement à froid) et à chaque signal.
- **Premier plan** : `willPresent` affiche la notification (bannière + son) pour le préfixe `photo-reminder.`.

`Info.plist` : `NSCameraUsageDescription` devient « Colette utilise l'appareil photo pour scanner vos documents et photographier votre bébé. »

## Présentation

`lib/features/photo_sharing/presentation/`

- **Providers** :
  - `broadcastListsProvider` (classe, keepAlive) : charge les listes ; méthodes `create(name)`, `rename(id, name)`, `delete(id)`, `addRecipient(id, recipient)` (ignore un numéro déjà présent dans la liste), `removeRecipient(id, phone)` ; chaque modification enregistre via le repository. Identifiants via `idGeneratorProvider`.
  - `photoReminderEnabledProvider` (classe, keepAlive) : lit et écrit l'interrupteur, puis appelle `photoReminderSync`.
  - `photoReminderSyncProvider` (fonction ou classe) : calcule `planPhotoReminders(now: clock.now(), lastSentAt, …)` si l'interrupteur est actif, sinon liste vide, puis `syncReminders`. Titre et texte de la notification depuis `S` (via `lookupS(const Locale('fr'))`, pas de `BuildContext`), prénom depuis `babyProfileProvider` (feature `baby`, provider public).
  - `photoSendControllerProvider` (`AsyncNotifier<SendReport?>`) : `send({list, photoPaths, body})` → `sendMessages` (`AsyncError(PhotoSharingFailure(messagesUnavailable))` si Messages est indisponible), puis si `anySent` : `saveLastSentAt(clock.now())` et `photoReminderSync` (supprime la notification du jour). `discardPhotos` dans tous les cas.
- **Pages et widgets** :
  - `widgets/photos_card.dart` : carte sur Aujourd'hui, « Photos » + « Dernier envoi : hier à 18 h 12 » (ou « Aucun envoi »), ouvre `/today/photos`.
  - `pages/photos_page.dart` : en tête le dernier envoi, puis `ListView.builder` des listes (nom, « N personnes »), bouton « Nouvelle liste ». Appui sur une liste : feuille « Prendre une photo » / « Choisir dans la galerie » ; bouton d'édition sur chaque ligne. État vide : texte d'explication + bouton de création.
  - `widgets/broadcast_list_editor_sheet.dart` : champ nom (obligatoire), liste des personnes (suppression par glissement), bouton « Ajouter une personne » (sélecteur de contacts), bouton « Supprimer la liste » avec confirmation.
  - `widgets/photo_send_sheet.dart` : vignettes des photos, champ texte facultatif (vide), bouton « Envoyer à N personnes » (désactivé si la liste est vide). Pendant l'envoi, indicateur ; à la fin, bilan « 4 envoyés · 1 annulé » (échecs mentionnés s'il y en a) et fermeture. Fermer la feuille sans envoyer appelle `discardPhotos`.
- **Paramètres** : `widgets/photo_reminder_switch.dart` (`SwitchListTile` « Rappel photo quotidien », sous-titre « Une notification par jour entre 8 h et 21 h ») ajouté dans `SettingsPage` sous `NotificationsSection`.
- **`PhotoReminderGate`** (`lib/app/`, comme `NotificationsGate`) : au démarrage, à chaque retour au premier plan (`AppLifecycleState.resumed`) et à chaque changement de prénom, lance `photoReminderSync` ; au démarrage et à chaque `pendingRouteSignals`, `takePendingRoute` puis navigation vers la page Photos (seulement si un foyer existe).
- **Routes** : `AppRoutes.todayPhotos = '/today/photos'`, `GoRoute(path: 'photos')` sous Aujourd'hui.
- **Strings** : toutes dans `app_fr.arb` (préfixe `photos…`), y compris le titre et le texte de la notification (« C'est l'heure d'une photo 📷 » / « Envoie des nouvelles de {prénom} à tes proches. », « bébé » si le profil manque).

## Erreurs

- Échec d'écriture des listes : `SnackBar` via `failureMessage`, état précédent conservé.
- Messages indisponibles (`MFMessageComposeViewController.canSendText()` faux, dont le simulateur) : message « Messages n'est pas disponible sur cet appareil », photos effacées.
- Échec natif du sélecteur ou de l'appareil photo : `SnackBar`, rien d'autre.
- `syncReminders` en échec : log `dart:developer`, jamais affiché.

## Tests

- **Domaine** : `planPhotoReminders` (14 dates dans `[8:00, 21:00[`, jour courant exclu si envoi aujourd'hui, heures passées exclues, même graine → même heure, changement de jour à minuit) ; `SendReport.anySent`.
- **Data** : DTO aller-retour et JSON invalide ; repository avec `SharedPreferences.setMockInitialValues` (défauts, écriture, relecture).
- **Présentation** (`pumpApp`, faux `PhotoSharingSystem` mocktail, `FixedClock`) : création, renommage, suppression de liste, ajout de contact (doublon ignoré) ; envoi → `lastSentAt` enregistré et `syncReminders` rappelé sans la date du jour ; bilan affiché ; envoi impossible → message ; interrupteur désactivé → `syncReminders([])` ; carte d'Aujourd'hui (aucun envoi / dernier envoi).
- **Simulateur** : sélecteur de contacts, galerie, appareil photo indisponible sur simulateur (erreur propre), notification programmée visible et appui qui ouvre la page. L'envoi réel (feuilles Messages) se vérifie uniquement sur iPhone.

## Écarts retenus à l'implémentation (2026-09-30)

- **Pluriels à zéro** : en français, CLDR range 0 dans `one` ; `photosSendTo`, `photosReportCancelled`, `photosReportFailed` ont un cas `=0` explicite. Nouveau libellé `photosErrorBusy` (« Une autre action est en cours. ») pour `PhotoSharingReason.busy`.
- **Pont Swift** : chaque présentation vérifie qu'elle a eu lieu (sinon la completion répond en erreur et libère le verrou) ; `isModalInPresentation` sur les sélecteurs et les feuilles Messages (fermeture par « Annuler » uniquement) ; la galerie réduit chaque photo à la lecture du fichier (ImageIO, `loadFileRepresentation`) au lieu de décoder 10 images pleine résolution ; `syncReminders` ne retire pas les identifiants qu'il reprogramme (un `add` remplace) — le retrait n'est pas synchrone.
- **Providers** : `BroadcastLists` sérialise ses écritures ; `PhotoSendController` enregistre l'envoi et resynchronise même si la feuille est démontée pendant l'envoi ; `PhotoReminderSync` relit le prénom dans Firestore (code foyer + `babyRepositoryProvider`, comme `FeedingPlanSync`) et n'échoue jamais ; `idGeneratorProvider` passe en keepAlive (lint).
- **Interface** : vignettes décodées à leur taille d'affichage ; marge basse de la liste pour le bouton flottant ; la feuille d'édition se ferme avant la suppression de la liste ; action VoiceOver « Retirer de la liste » ; feuille d'envoi défilante et non fermable pendant l'envoi (sauf glissement de la feuille, limite Flutter) ; sans foyer, `PhotoReminderGate` retire les rappels programmés ; `dayLabel` déplacé dans `core/dates/`.
- **Suivis non traités** : deux synchronisations au démarrage (prénom en chargement puis chargé), course possible entre la reprise du minuteur de biberon et l'ouverture par la notification photo au lancement à froid, formats national / international d'un même numéro non rapprochés.
