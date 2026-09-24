# Colette — Documents du dossier iCloud partagé

Date : 2026-09-22 ; lot 3 (suivi iCloud en direct, suppression, ouverture dans Fichiers) ajouté le 2026-09-23 après les premiers essais sur iPhone. Complète la spec v1 (`2026-09-21-colette-v1-design.md`).

## 1. Problème

Les parents ont un dossier iCloud Drive partagé entre leurs deux comptes Apple (ordonnances, carnet de santé, papiers administratifs). Ils veulent le consulter depuis Colette, et si possible y ajouter des documents depuis l'app : scan d'une ordonnance, import d'un PDF reçu par mail.

Besoin exprimé : lecture obligatoire, écriture en bonus. Le dossier est organisé en sous-dossiers.

## 2. Décision : dossier choisi via le sélecteur iOS, accès persistant par bookmark

Une app tierce ne parcourt pas iCloud Drive librement. Elle obtient l'accès à un dossier via `UIDocumentPickerViewController` en mode dossier (iOS 13+), puis conserve cet accès entre les lancements avec un bookmark de sécurité : `url.bookmarkData()` au moment du choix, `URL(resolvingBookmarkData:bookmarkDataIsStale:)` puis `startAccessingSecurityScopedResource()` à chaque utilisation.

Chaque parent choisit une fois le dossier partagé sur son iPhone. Le dossier apparaissant dans l'iCloud Drive des deux comptes, rien ne transite par Firestore : le choix est purement local à l'appareil. iCloud reste la source de vérité et Apple gère le partage.

Tout le code qui touche au système de fichiers, au téléchargement iCloud, à l'aperçu, au scanner et aux sélecteurs vit dans un pont Swift interne au projet. Flutter ne manipule que des chemins relatifs à la racine choisie et ne connaît jamais de chemin absolu.

Alternatives écartées :

- **Packages Flutter existants** (`file_picker`, `open_filex`, `image_picker`). `file_picker` copie les fichiers dans un dossier temporaire et ne conserve pas l'accès sécurisé au dossier choisi : après relancement, l'accès échoue. Il faudrait de toute façon du Swift pour le bookmark.
- **Conteneur iCloud propre à l'app** (`icloud_storage`). Accès automatique sans sélecteur, mais oblige à déplacer le dossier existant dans le dossier de l'app, demande une configuration iCloud sur le compte développeur, et le partage d'un dossier d'app est moins souple.
- **Firebase Storage**. Duplique le dossier iCloud, coûte du stockage, ajoute une surface de sécurité sans bénéfice.

## 3. Règles

| Sujet | Règle |
| --- | --- |
| Racine | Un seul dossier racine par iPhone, stocké en bookmark dans `UserDefaults` sous la clé `colette.documents.rootBookmark`. Aucune donnée Firestore. |
| Chemins | Flutter manipule des chemins relatifs à la racine, séparateur `/`, sans `/` initial. La racine est `''`. Un chemin contenant `..` ou commençant par `/` est refusé avec `accessDenied`. |
| Résolution | Le bookmark est résolu à chaque appel, jamais mis en cache. S'il est périmé (`isStale`), il est régénéré et réécrit. Absence de bookmark (rien choisi, ou dossier oublié) : `noFolder`. Bookmark présent mais qui ne se résout pas (URL invalide, `startAccessingSecurityScopedResource` refusé, dossier renommé ou supprimé) : `accessDenied`. |
| Listage | Sous-dossiers d'abord, triés par nom (insensible à la casse, `compareTo` sur la version minuscule). Puis fichiers par date de modification décroissante, nom croissant à égalité. Les fichiers cachés (nom commençant par `.`) sont exclus, sauf les placeholders iCloud, normalisés (voir Données). La lecture du dossier et des métadonnées s'exécute hors du thread principal (`DispatchQueue.global(qos: .userInitiated)`) ; dans un flux de dossier, la portée sécurisée reste ouverte jusqu'au désabonnement et chaque liste est envoyée sur le thread principal. |
| Flux d'un dossier | Un dossier affiché est observé en direct, pas photographié une fois. Chaque abonnement a son propre canal d'événements, ouvert par `openFolderStream` (section 5) et piloté par un `DocumentsFolderWatcher`. À l'abonnement, l'observateur liste le dossier comme ci-dessus et envoie cette première liste tout de suite. Il démarre ensuite une `NSMetadataQuery` de portée `NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope`, `notificationBatchingInterval` de 0,5 s, dont le prédicat est un OU de `NSMetadataItemPathKey BEGINSWITH` sur les deux formes du chemin du dossier, `/private/var/…` et `/var/…` (iOS remonte l'une ou l'autre selon la source). Les enfants directs sont retenus en code : le dossier parent du fichier réel (placeholder normalisé) et le dossier observé sont comparés sous leur forme canonique (`resolvingSymlinksInPath`). À chaque `NSMetadataQueryDidFinishGathering` ou `DidUpdate`, Swift recalcule un dictionnaire de progression, clé = dossier canonique + nom réel du fichier, valeur = `NSMetadataUbiquitousItemPercentDownloadedKey` / 100 bornée entre 0 et 1, puis reliste le dossier hors thread principal (un seul listage à la fois ; une demande arrivée pendant un listage en relance un après). Un fichier du dictionnaire que le listage ne donne pas `downloaded` est envoyé `downloading` avec ce `downloadProgress`. L'état « en téléchargement » est collant : un fichier n'entre dans le dictionnaire qu'avec `NSMetadataUbiquitousItemIsDownloadingKey` vrai et un pourcentage (un placeholder jamais demandé ne paraît pas en téléchargement) ; une fois suivi, il garde son dernier pourcentage connu, même quand la requête ne le donne plus, jusqu'à ce que le listage le dise `downloaded`, qu'il disparaisse des résultats de la requête, qu'il atteigne `NSMetadataUbiquitousItemDownloadingStatusCurrent`, ou qu'il porte `NSMetadataUbiquitousItemDownloadingErrorKey`. Il retombe alors sur le statut du listage, `notDownloaded` s'il n'est pas arrivé, que Flutter traduit en « pas encore téléchargé » (section 6). Flutter ne voit donc jamais `notDownloaded` entre la fin du téléchargement et le remplacement du placeholder sur le disque. Diagnostics `os_log`, lus dans la Console macOS pour le point 22 de la section 8 : échec du démarrage de la requête (niveau erreur), nombre de résultats à la fin de la collecte initiale (niveau info). Un abonnement par dossier affiché, chacun gardant sa portée sécurisée ouverte jusqu'au désabonnement (`onCancel`) ; la requête est arrêtée et la portée refermée à ce moment (drapeau `stopped` : `stop` est idempotent, un `start` après `stop` est sans effet). Si la requête ne remonte rien (dossier partagé hors de sa portée), le comportement dégrade vers la liste initiale, jamais vers une liste vide. Toute écriture (`scan`, `importFile`) ou suppression (`delete`) réussie force en plus un relistage du flux du dossier concerné, sans dépendre de la requête. |
| Placeholders | Si `x.pdf` et son placeholder `.x.pdf.icloud` existent tous les deux (téléchargement en cours au moment du listage), une seule entrée est renvoyée pour le chemin `x.pdf` : le fichier réel prime sur le placeholder. |
| Téléchargement | Méthode `download` : `startDownloadingUbiquitousItem` sur le fichier réel, réponse immédiate (`null`), sans verrou, sans attente. La progression et la fin remontent par le flux du dossier. Plusieurs téléchargements peuvent courir en parallèle. Fichier déjà lisible : réponse immédiate sans rien lancer. |
| Aperçu | `QLPreviewController` natif. `preview` n'attend aucun téléchargement : si le fichier n'est pas lisible localement (placeholder, ou statut ni `current` ni `downloaded`), réponse `io` immédiate. L'enchaînement « télécharger puis ouvrir » est piloté côté Flutter par `DocumentsPreviewController` (section 6). |
| Suppression | Méthode `delete` : fichiers seulement, un chemin de dossier est refusé avec `io`. Résout le fichier réel ou son placeholder, puis, hors thread principal et sans verrou, coordonne la suppression sur l'URL logique, celle du fichier réel même quand seul le placeholder existe (`NSFileCoordinator.coordinate(writingItemAt:options: .forDeleting)`). Dans la coordination : si le fichier réel existe, `FileManager.trashItem` est tenté d'abord pour qu'il rejoigne « Récemment supprimés » de Fichiers, `removeItem` sert de repli si iOS refuse la corbeille ; si seul le placeholder `.x.ext.icloud` existe, c'est lui qui est supprimé (`removeItem`). Après succès, le flux du dossier parent est relisté. « Récemment supprimés » conserve un fichier iCloud trente jours, mais qu'un fichier supprimé par Colette y arrive bien (par `trashItem` ou par le repli, placeholder compris) ne se vérifie que sur iPhone réel (point 20 de la section 8). |
| Ouvrir dans Fichiers | Méthode `openInFiles` : résout le dossier (racine ou sous-dossier), referme la portée sécurisée (le chemin absolu reste valable pour le lien, et Fichiers a ses propres droits), construit l'URL avec `URLComponents` (schéma `shareddocuments`, hôte vide, chemin absolu du dossier tel que résolu par le bookmark, en pratique `/private/var/…`), soit `shareddocuments:///…` encodé en pourcent, et l'ouvre avec `UIApplication.shared.open`. Réponse `null` si iOS a ouvert l'URL, `io` sinon. Pas de `LSApplicationQueriesSchemes` (pas de `canOpenURL`). |
| Scan | `VNDocumentCameraViewController`. Les pages sont rendues dans un PDF unique, nommé `Scan {jj}-{MM}-{aaaa} {HH}h{mm}.pdf` avec l'horloge de l'app (`clockProvider`), écrit dans le dossier courant. |
| Import | `UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)`. Le fichier est copié dans le dossier courant sous son nom d'origine. |
| Collision de nom | Résolue en Swift juste avant l'écriture : `nom (2).ext`, `nom (3).ext`, etc. |
| Écriture | Toujours via `NSFileCoordinator.coordinate(writingItemAt:)` dans la portée de `startAccessingSecurityScopedResource`. Le rendu du PDF et la coordination de fichier s'exécutent hors du thread principal (`DispatchQueue.global(qos: .userInitiated)`) ; la réponse au canal revient sur le thread principal une fois la portée refermée. Le fichier temporaire de l'import (copie `asCopy` du sélecteur système) est supprimé juste après la copie dans le dossier iCloud. Les pages scannées sont mises en page sur une page A4, portrait ou paysage selon l'orientation de l'image, avec un centrage qui conserve le rapport d'aspect (aucun étirement). Le `fileName` d'un scan (et le nom retenu pour une collision) contenant `/`, valant `.` ou `..`, ou vide, est refusé avec `accessDenied`. Un scan sans page (annulé après la première photo, ou toutes les pages supprimées avant validation) échoue avec `cancelled`, pas avec un PDF vide. |
| Opérations concurrentes | Un seul verrou global dans `DocumentsPlugin` couvre les quatre opérations qui présentent un écran système (`pickRootFolder`, `preview`, `scan`, `importFile`), et seulement le temps où cet écran est affiché : depuis le lot 3, `preview` n'attend plus de téléchargement, donc le verrou n'est plus tenu pendant une attente réseau. Toute deuxième opération, du même type ou d'un autre, est refusée immédiatement avec `cancelled` sans toucher au presenter ni au store ; l'UI l'ignore comme n'importe quelle annulation, sans perturber l'opération en cours. Le verrou est libéré sur chaque fin possible (succès, échec, annulation, présentation impossible), sans délai d'expiration : il repose sur les complétions UIKit et les délégués système, toujours appelés ; un délai qui relâcherait le verrou pendant qu'un écran système est encore affiché réintroduirait les présentations superposées. Les gardes par écran du presenter restent en seconde ligne. `rootFolder`, `forgetRootFolder`, `download`, `delete`, `openInFiles` et le flux de dossier ne prennent pas le verrou. Cas particulier : un aperçu déclenché automatiquement à la fin d'un téléchargement pendant qu'un autre écran système est ouvert est refusé avec `cancelled` ; le contrôleur Flutter revient au repos et un nouveau tap ouvre le fichier, désormais téléchargé. |
| Présentation | Les écrans système (sélecteurs, `QLPreviewController`, scanner) sont présentés sur le contrôleur au sommet de la pile de présentation de la scène `foregroundActive` (ou, à défaut, la première scène avec une fenêtre clé). Si la présentation n'aboutit pas (aucune scène active, vue non prête), l'opération échoue avec `io`, pas silencieusement. |
| Hors ligne | Le listage fonctionne (iCloud garde les métadonnées). Un fichier non téléchargé reste visible avec l'icône nuage ; un tap lance `download`, qui n'aboutit pas. Si iCloud signale un téléchargement puis une erreur, la ligne garde son indicateur jusque-là, puis repasse à `notDownloaded` et l'UI affiche « Ce document n'est pas encore téléchargé sur cet iPhone ». Sans réseau, iCloud peut aussi ne jamais signaler de téléchargement : la ligne garde alors l'indicateur indéterminé du contrôleur, sans message, jusqu'au retour du réseau ou jusqu'à ce qu'on quitte la page (point 26 de la section 8, section 11). Aucun état Flutter persisté. |
| Annulation | Sélecteur, scanner ou import annulés : `cancelled`. L'UI ne montre rien. |
| Plan biberons, Cloud Functions, Firestore | Non concernés. |

## 4. Données

### Entités de domaine (`lib/features/documents/domain/entities/`)

```dart
/// Dossier racine choisi par l'utilisateur.
@freezed
abstract class DocumentRoot with _$DocumentRoot {
  const factory DocumentRoot({required String name}) = _DocumentRoot;
}

/// Statut de téléchargement iCloud d'un fichier.
enum DownloadStatus { downloaded, downloading, notDownloaded }

/// Entrée d'un dossier : sous-dossier ou fichier.
@freezed
abstract class DocumentEntry with _$DocumentEntry {
  const factory DocumentEntry({
    required String name,           // nom affiché, sans préfixe « . » ni suffixe « .icloud »
    required String path,           // chemin relatif à la racine, ex. « Ordonnances/2026 »
    required bool isDirectory,
    required int size,              // octets, 0 pour un dossier
    required DateTime modifiedAt,
    required DownloadStatus downloadStatus, // toujours downloaded pour un dossier
    double? downloadProgress,               // 0 à 1 pendant un téléchargement, null sinon (lot 3)
  }) = _DocumentEntry;
}
```

### Failure

Ajout dans `lib/core/result/failure.dart`, sur le modèle de `ValidationFailure` :

```dart
/// Raison d'une [DocumentsFailure].
enum DocumentsReason { noFolder, accessDenied, cancelled, io }

/// Erreur du pont natif documents.
final class DocumentsFailure extends Failure {
  const DocumentsFailure(this.reason);
  final DocumentsReason reason;
}
```

`DocumentsFailure` a l'égalité par valeur (`==`/`hashCode` sur `reason`), nécessaire pour comparer des `Either<Failure, T>` dans les tests.

`core/ui/failure_message.dart` traduit `noFolder` et `accessDenied` par `documentsErrorAccess`, et `io` par `documentsErrorIo` (« Impossible d'accéder à ce document », nouvelle clé). `cancelled` tombe sur `errorUnknown`, message générique jamais affiché : chaque point d'appel l'ignore explicitement plutôt que de compter sur l'absence de traduction.

`documentsErrorWrite` (« Impossible d'enregistrer le document ») n'est pas produit par `failureMessage()` : la page Documents l'affiche elle-même dans une `SnackBar` quand un scan ou un import échoue avec `io`, à la place du message générique renvoyé par `failureMessage()`. De même, `documentsErrorNotDownloaded` est affiché par la tuile de fichier quand son aperçu échoue avec `io`, avant de retomber sur `failureMessage()` pour les autres échecs.

### Placeholders iCloud

Un fichier non téléchargé apparaît dans `FileManager.contentsOfDirectory` sous la forme `.{nom}.{ext}.icloud`. Swift le normalise : `name` sans le `.` initial ni le suffixe `.icloud`, `path` construit avec ce nom normalisé, `downloadStatus = notDownloaded`. Pour les autres fichiers, le statut vient de `URLResourceValues.ubiquitousItemDownloadingStatus` (`current` → `downloaded`, sinon `downloading` si `ubiquitousItemIsDownloading`, sinon `notDownloaded`). Un fichier hors iCloud (dossier local choisi) est `downloaded`. `downloadProgress` vient de la `NSMetadataQuery` du flux (`NSMetadataUbiquitousItemPercentDownloadedKey` / 100, borné entre 0 et 1) et n'est renseigné que pour un fichier `downloading` ; la liste initiale d'un abonnement, prise avant la requête, n'a pas de pourcentage (`null`) et la tuile affiche alors un indicateur indéterminé.

Avant tout accès à un fichier par son chemin relatif, Swift tente d'abord `{dossier}/{nom}`, puis le placeholder `{dossier}/.{nom}.icloud`.

## 5. Contrat du canal natif `colette/documents`

`MethodChannel` nommé `colette/documents`. Chaque méthode renvoie un résultat ou lève une `PlatformException` dont `code` vaut `noFolder`, `accessDenied`, `cancelled` ou `io`. Tout autre code est mappé sur `UnknownFailure`.

| Méthode | Arguments | Retour |
| --- | --- | --- |
| `pickRootFolder` | aucun | `{name: String}` ; `cancelled` si annulé |
| `rootFolder` | aucun | `{name: String}` ou `null` |
| `forgetRootFolder` | aucun | `null` |
| `openFolderStream` | `{path: String}` | `{channel: String}`, nom du canal d'événements à écouter |
| `download` | `{path: String}` | `null` aussitôt le téléchargement lancé (ou si le fichier est déjà lisible) |
| `delete` | `{path: String}` | `null` ; `io` pour un dossier ou un fichier introuvable |
| `openInFiles` | `{path: String}` | `null` ; `io` si iOS n'ouvre pas Fichiers |
| `preview` | `{path: String}` | `null`, une fois l'aperçu fermé ; `io` immédiat si le fichier n'est pas lisible localement |
| `scan` | `{path: String, fileName: String}` | `{name: String}` du PDF créé (après résolution de collision) ; `cancelled` |
| `importFile` | `{path: String}` | `{name: String}` du fichier copié ; `cancelled` |

Flux d'un dossier (lot 3, remplace l'ancienne méthode `list`). Un `FlutterEventChannel` n'accepte qu'un abonné à la fois, or la page racine et une sous-page poussée observent chacune leur dossier en même temps : chaque abonnement a donc son propre canal. Flutter appelle d'abord `openFolderStream` (`{path: String}` → `{channel: String}`, nom de la forme `colette/documents/folder/{n}`, `n` croissant) ; Swift ouvre la racine, résout le dossier (erreurs `noFolder`/`accessDenied` renvoyées ici, de façon synchrone), crée le canal et son observateur (`DocumentsFolderWatcher`). Flutter s'abonne ensuite au canal reçu (`receiveBroadcastStream()`, sans argument). Chaque événement est la liste complète du dossier, `List<Map>` : `{name, path, isDirectory, size, modifiedAt (ms epoch UTC), downloadStatus ('downloaded' \| 'downloading' \| 'notDownloaded'), downloadProgress (double, absent hors téléchargement)}`. Une erreur est envoyée comme `FlutterError` avec les mêmes codes que le `MethodChannel`, puis le flux se termine (`FlutterEndOfEventStream`). Contrat : au moins un événement (liste, ou erreur puis fin) part toujours après l'abonnement, avant même le démarrage de la requête de métadonnées, sinon un désabonnement qui a couru en parallèle de `openFolderStream` ne libérerait jamais le canal ; le désabonnement est idempotent (Flutter l'envoie aussi après une erreur ou une fin). Les événements suivants partent à chaque mise à jour iCloud (`notificationBatchingInterval` de 0,5 s) et après chaque écriture ou suppression réussie via le `MethodChannel` (le plugin garde les observateurs par nom de canal et relance ceux dont le chemin relatif correspond). Le désabonnement arrête la requête, referme la portée sécurisée et libère le canal. Un canal ouvert par `openFolderStream` mais jamais écouté (redémarrage à chaud entre l'appel et l'abonnement) garde sa portée ouverte jusqu'à la fin du processus : cas limite accepté, en développement seulement.

Côté Swift : `ios/Runner/Documents/DocumentsPlugin.swift` (enregistrement du `MethodChannel`, dispatch, création à la demande des canaux de dossier et de leur `DocumentsFolderStreamHandler` ; le plugin garde deux dictionnaires par nom de canal, observateurs et `FlutterEventChannel`, pour forcer un relistage après écriture ou suppression et libérer le canal au désabonnement), `DocumentsFolderWatcher.swift` (un observateur par abonnement : première liste, `NSMetadataQuery`, progression collante, relistage, envoi sur le `FlutterEventSink`, arrêt), `DocumentsStore.swift` (bookmark, résolution, portée sécurisée), `DocumentsLister.swift` (listage, normalisation des placeholders, report de la progression, chemins canoniques, `locate`, `isAvailable`, `startDownload`), `DocumentsWriter.swift` (PDF depuis les images du scan, copie, collision, suppression coordonnée), `DocumentsPresenter.swift` (sélecteurs, `QLPreviewController`, `VNDocumentCameraViewController`, présentés depuis le contrôleur au sommet de la pile de présentation de la scène active, pas depuis un `rootViewController` fixe — voir section 3, « Présentation »), `DocumentsError.swift` (mapping des raisons vers `FlutterError`). Enregistré dans `AppDelegate.didInitializeImplicitFlutterEngine`. Si le `registrar` du plugin est indisponible au démarrage, `DocumentsPlugin.register` renonce sans planter et journalise via `os_log` (canal non enregistré).

`Info.plist` : ajout de `NSCameraUsageDescription` (« Colette utilise l'appareil photo pour scanner vos documents. »). Aucun entitlement iCloud nécessaire : le sélecteur de dossier suffit.

Les sept fichiers Swift (`DocumentsPlugin.swift`, `DocumentsFolderWatcher.swift`, `DocumentsStore.swift`, `DocumentsLister.swift`, `DocumentsWriter.swift`, `DocumentsPresenter.swift`, `DocumentsError.swift`) sont référencés dans `Runner.xcodeproj` par `ios/scripts/add_documents_sources.rb` (gem `xcodeproj`, livrée avec CocoaPods), plutôt qu'à la main dans Xcode : le script ajoute le groupe et les fichiers manquants à la cible `Runner`, et ne fait rien s'ils y sont déjà (idempotent, vérifié en le relançant deux fois de suite).

## 6. Architecture Flutter

```
lib/features/documents/
  domain/
    entities/document_root.dart, document_entry.dart, download_status.dart
    repositories/documents_repository.dart
    use_cases/sort_document_entries.dart      dossiers puis fichiers, règle de la section 3
    use_cases/build_scan_file_name.dart       « Scan jj-MM-aaaa HHhmm.pdf » depuis un DateTime (préfixe « Scan » fixe, le domaine n'a pas de l10n)
    use_cases/parent_path.dart                dossier parent d'un chemin relatif ('' à la racine, lot 3)
  data/
    dtos/document_entry_dto.dart              fromMap depuis la map du canal
    native_documents_repository.dart          MethodChannel + un EventChannel par abonnement, mapping PlatformException → Failure
  presentation/
    providers/documents_providers.dart        documentsRepositoryProvider (keepAlive),
                                              documentsFolderProvider(path) (flux, autoDispose, retry: noRetry)
    providers/documents_root.dart             DocumentsRoot : FutureOr<DocumentRoot?>, pick(), forget()
    providers/documents_preview_controller.dart  DocumentsPreviewController(path) : famille autoDispose, open() (télécharge puis ouvre)
    providers/documents_delete_controller.dart   DocumentsDeleteController(folderPath) : famille autoDispose, delete(path)
    providers/documents_open_in_files_controller.dart  DocumentsOpenInFilesController(path) : famille autoDispose, open()
    providers/documents_write_controller.dart    DocumentsWriteController(folderPath) : famille autoDispose, scan(), importFile()
    pages/documents_page.dart
    widgets/documents_card.dart               carte sur Aujourd'hui
    widgets/document_entry_tile.dart          ligne (icône, progression, tap)
    widgets/document_delete_dismissible.dart  glissement de suppression des lignes de fichier (lot 3)
    widgets/documents_open_in_files_button.dart  action de l'AppBar
    widgets/documents_add_menu.dart           bouton « + » et ses deux actions
    widgets/documents_lost_access_view.dart
    widgets/documents_root_section.dart       ligne dans la section Foyer des Réglages
```

### Repository

```dart
abstract interface class DocumentsRepository {
  Future<Either<Failure, DocumentRoot?>> rootFolder();
  Future<Either<Failure, DocumentRoot>> pickRootFolder();
  Future<Either<Failure, void>> forgetRootFolder();
  Stream<Either<Failure, List<DocumentEntry>>> watch(String path);   // lot 3, remplace list()
  Future<Either<Failure, void>> download(String path);                // lot 3
  Future<Either<Failure, void>> preview(String path);
  Future<Either<Failure, void>> delete(String path);                  // lot 3
  Future<Either<Failure, void>> openInFiles(String path);             // lot 3
  Future<Either<Failure, String>> scan({required String folderPath, required String fileName});
  Future<Either<Failure, String>> importFile({required String folderPath});
}
```

`NativeDocumentsRepository` (constructeur `const`) reçoit le `MethodChannel` en constructeur (injectable en test). Chaque appel passe par une méthode privée `_call`, calquée sur `guard()` mais locale au repository : elle convertit un `PlatformException` en `DocumentsFailure` selon son `code` (`noFolder`, `accessDenied`, `cancelled`, `io`), et tout autre code ou exception en `UnknownFailure` avec un log. Le mapping n'est volontairement pas fait par `guard()` de `core/result`, pour ne pas coupler `core` aux codes du canal `colette/documents`. `watch(path)` appelle `openFolderStream` puis s'abonne à `EventChannel(nom reçu).receiveBroadcastStream()`, mappe chaque événement en `Right(List<DocumentEntry>)` via `DocumentEntryDto.fromMap`, et convertit une `PlatformException` (de `openFolderStream` ou du flux) en `Left(DocumentsFailure)` (même table que `_call`) suivi de la fin du flux. Seul le `MethodChannel` est injecté en constructeur : le nom du `EventChannel` vient de Swift, et les tests installent leur `MockStreamHandler` sur le nom que renvoie leur `openFolderStream` mocké.

### Providers

- `documentsRepositoryProvider` : `keepAlive`, construit `NativeDocumentsRepository(const MethodChannel('colette/documents'))`.
- `DocumentsRoot` (`@Riverpod(keepAlive: true, retry: noRetry)`) : `build()` appelle `rootFolder()`. `pick()` : si un `build` initial ou un `pick`/`forget` précédent est encore en vol (`state.isLoading`), renvoie aussitôt `right(false)` sans toucher à l'état, pour qu'un résultat tardif ne l'écrase pas après coup. Sinon, passe en `AsyncLoading` puis appelle `pickRootFolder()`. Succès : `AsyncData(root)`, `right(true)`, invalide tous les `documentsFolderProvider`. Échec `cancelled` : restaure l'état précédent, `right(false)`. Autre échec : restaure aussi l'état précédent, `left(failure)` — c'est à l'appelant de l'afficher. `forget()` a la même garde de concurrence ; succès : `AsyncData(null)`, `right(null)`, invalide les `documentsFolderProvider` ; échec : restaure l'état précédent, `left(failure)`.
- `documentsFolderProvider(String path)` : `@Riverpod(retry: noRetry)` (`autoDispose` implicite), fonction `Stream<List<DocumentEntry>>` qui mappe `watch(path)` : chaque `Right` est trié par `sortDocumentEntries`, un `Left` est relancé en exception pour que l'UI le reçoive en `AsyncError`. Riverpod conserve la dernière liste (`hasValue`) pendant une invalidation : le tirer-pour-rafraîchir invalide le provider, ce qui se désabonne puis se réabonne au flux natif, donc force un relistage.
- `DocumentsPreviewController(String path)` (`@riverpod`, famille `autoDispose`, `FutureOr<void> build(path) {}`) : `open(DocumentEntry entry)` (lot 3, remplace `preview()`), ignoré si une ouverture est déjà en vol (`if (state.isLoading) return;`). Si `entry.downloadStatus == downloaded` : `AsyncLoading`, `repository.preview(path)`, puis `AsyncData(null)` (succès ou `cancelled`) ou `AsyncError`. Sinon : `AsyncLoading`, `repository.download(path)` (échec → `AsyncError`), puis le contrôleur écoute `documentsFolderProvider(parent)` (`parent` = `parentPath(path)`, chemin sans le dernier segment, `''` à la racine) et attend l'entrée de même `path` : `downloaded` → `preview(path)` comme ci-dessus ; `notDownloaded` après avoir vu `downloading` → `AsyncError(DocumentsFailure(io))` ; entrée disparue (fichier supprimé ici ou sur l'autre iPhone) → `AsyncData(null)` sans message ; `notDownloaded` avant tout `downloading` (iCloud n'a pas encore pris la demande en compte) et `downloading` → continue d'attendre ; un `AsyncLoading` du dossier (tirer-pour-rafraîchir, invalidation) remet `seenDownloading` à faux, car la première liste du flux natif reconstruit précède sa requête de métadonnées et y montre un placeholder `notDownloaded` sans que le téléchargement ait échoué. Mécanisme : abonnement par `ref.listen` d'abord, puis évaluation à la main de la valeur courante (`handle(ref.read(folder))`), avec un drapeau `settled` qui garantit une seule issue. Pas de `fireImmediately: true` : Riverpod appelle un tel écouteur avant de renvoyer la souscription, si bien qu'une issue immédiate (tuile périmée, fichier déjà téléchargé) aurait tenté de fermer une souscription pas encore affectée et l'aurait laissée ouverte. L'écoute est fermée dès la première issue et à la destruction du contrôleur (`ref.onDispose`). `open()` et `_preview()` vérifient `ref.mounted` après leur `await` : la ligne a pu être démontée entre-temps (page quittée, défilement), et le contrôleur `autoDispose` détruit avec elle. Un `cancelled` renvoyé par `preview` (verrou pris par un autre écran système) remet `AsyncData(null)` : le fichier est téléchargé, un nouveau tap l'ouvre. Pas de délai d'expiration côté Flutter : la progression est visible sur la ligne, et quitter la page détruit le contrôleur (`autoDispose`) sans arrêter le téléchargement iCloud. Une instance par chemin de fichier : chaque ligne affiche son propre indicateur (`ref.watch(...).isLoading`) et écoute ses propres erreurs (`ref.listen`) sans affecter les autres lignes.
- `DocumentsDeleteController(String folderPath)` (`@riverpod`, famille `autoDispose`, lot 3) : `delete(String path)` : ignoré si une suppression est déjà en vol (`if (state.isLoading) return;`), sinon `AsyncLoading`, `repository.delete(path)`, puis, si le contrôleur est toujours monté (`ref.mounted`, le widget appelant a pu être démonté pendant l'`await`), `AsyncData(null)` ou `AsyncError`. Pas d'invalidation du dossier : Swift force le relistage du flux après la suppression. Famille par dossier pour la même raison que `DocumentsWriteController`.
- `DocumentsOpenInFilesController(String path)` (`@riverpod`, famille `autoDispose`, lot 3) : `open()` : ignoré si déjà en vol (`if (state.isLoading) return;`), sinon `AsyncLoading`, `repository.openInFiles(path)`, puis, si toujours monté (`ref.mounted`), `AsyncData(null)` ou `AsyncError`.
- `DocumentsWriteController(String folderPath)` (`@riverpod`, famille `autoDispose`, `FutureOr<void> build(folderPath) {}`) : `scan()` calcule le nom avec `clockProvider` et `buildScanFileName`, `importFile()` n'a pas de nom à calculer. Les deux passent par une méthode privée `_run` : `AsyncLoading`, puis sur succès `AsyncData(null)` (depuis le lot 3, plus d'invalidation de `documentsFolderProvider(folderPath)` : Swift force le relistage du flux du dossier après chaque écriture réussie, et une invalidation fermerait puis rouvrirait inutilement le flux natif (canal, requête, portée)) ; `cancelled` → `AsyncData(null)` sans erreur ; autre échec → `AsyncError`. Famille par `folderPath` : la page racine et une sous-page poussée observent chacune leur propre instance, sans se déclencher mutuellement.

`@Riverpod(retry: noRetry)` sur `documentsFolderProvider` et `DocumentsRoot` : sans ça, Riverpod 3 relance automatiquement jusqu'à dix fois un `build` qui lève, en gardant `AsyncLoading` affiché pendant les tentatives — une `DocumentsFailure` (dossier perdu, par exemple) resterait masquée derrière un spinner plusieurs secondes avant de remonter. `noRetry` (`lib/core/result/no_retry.dart`, une politique `Duration? Function(int, Object)` qui renvoie toujours `null`) fait remonter la `Failure` immédiatement.

Les widgets qui appellent `pick()` ou `forget()` (`DocumentsCard`, `DocumentsRootSection`, `DocumentsLostAccessView`) affichent eux-mêmes la `SnackBar` d'échec avec `failureMessage()`, plutôt que de passer par un `ref.listen` sur un contrôleur dédié : `pick()`/`forget()` renvoient directement l'`Either`. Ils capturent `ScaffoldMessenger.of(context)` et `S.of(context)` avant l'`await`, car `pick()`/`forget()` passent par `AsyncLoading`, ce qui peut reconstruire ou démonter le widget appelant pendant l'attente.

### Navigation

Route imbriquée dans la branche Aujourd'hui pour garder la barre d'onglets et le retour iOS :

```dart
static const todayDocuments = '/today/documents';
static const documentsPathParam = 'path';   // paramètre de requête, chemin relatif encodé
```

`GoRoute(path: 'documents', builder: (_, state) => DocumentsPage(path: state.uri.queryParameters['path'] ?? ''))` sous la route `today`. Entrer dans un sous-dossier fait un `context.push('/today/documents?path=Ordonnances%2F2026')`. Cette route n'est pas ajoutée aux chemins autorisés de `notifications_gate.dart`.

## 7. UI

### Carte « Documents » sur Aujourd'hui

Placée après `DayCountersRow`. `switch` sur `documentsRootProvider` :

- `AsyncData(value: null)` : `ColetteCardSurface` avec icône dossier, texte `documentsCardEmptyBody` et bouton `documentsCardPick`. Tap : `ref.read(documentsRootProvider.notifier).pick()`.
- `AsyncData(value: DocumentRoot root)` : titre `documentsCardTitle`, sous-titre `root.name`, chevron. Tap : `context.push(AppRoutes.todayDocuments)`.
- `AsyncLoading()` : la carte avec un indicateur discret, non tappable.
- `AsyncError()` : même rendu que sans dossier.

### Page Documents

`AppBar` avec le nom du dossier courant (nom de la racine si `path` vide) et, en action à droite (lot 3), `DocumentsOpenInFilesButton(path)` : `IconButton` icône `folder_open_outlined`, tooltip `documentsOpenInFiles`, qui appelle `DocumentsOpenInFilesController(path).open()` ; présent avec une liste, une liste vide ou pendant un rechargement, absent sur `AsyncError` (donc absent sur la vue « accès perdu »). Pendant l'appel, le bouton est désactivé. `switch` sur `documentsFolderProvider(path)` :

- `AsyncData` vide (et sans rechargement en cours) : `EmptyState` avec `documentsEmptyFolder`.
- `AsyncData`, y compris un rafraîchissement en cours (`hasValue` reste vrai pendant un `AsyncLoading` avec `previousData`) : `ListView.builder` de `DocumentEntryTile`, dans un `RefreshIndicator` qui rafraîchit le provider. La liste actuelle reste affichée pendant le tirer-pour-rafraîchir, plutôt que de basculer sur le spinner ; après une écriture ou une suppression réussie, le provider n'est pas invalidé : le flux natif renvoie la nouvelle liste, qui remplace l'ancienne sans état de chargement. Si le rafraîchissement échoue, le provider passe en `AsyncError` et la page affiche la vue « accès perdu » ou le message générique à la place de la liste (les bras `AsyncError` précèdent les bras `hasValue`) ; le `try/catch` de `onRefresh` sert seulement à journaliser l'erreur (`log(..., name: 'colette')`) au lieu de la laisser fuir en exception non gérée depuis le `RefreshIndicator`.
- Aucune valeur encore reçue (premier chargement) : indicateur centré.
- `AsyncError(error: DocumentsFailure(reason: noFolder || accessDenied))` : `DocumentsLostAccessView` avec `documentsLostAccessBody` et un bouton `documentsCardPick` qui appelle `pick()` puis, en cas de succès, `context.go(AppRoutes.todayDocuments)` pour repartir de la racine.
- Autre `AsyncError` : `EmptyState` avec le message générique de `failureMessage`.

`EmptyState` a un slot `action` optionnel (`Widget?`, affiché sous le message) ; `DocumentsLostAccessView` l'utilise pour son bouton `documentsCardPick`.

`DocumentEntryTile` : icône `folder` pour un dossier, `picture_as_pdf` pour `.pdf`, `image` pour `.jpg`, `.jpeg`, `.png`, `.heic`, `insert_drive_file` sinon. Titre : `name`. Sous-titre : date de modification formatée `d MMM yyyy`, absente pour un dossier. Trailing : chevron pour un dossier ; pour un fichier, `CircularProgressIndicator(value: downloadProgress)` si `downloading` avec un pourcentage connu, indicateur indéterminé si `downloading` sans pourcentage ou si le contrôleur d'aperçu de cette ligne est en vol (`isLoading`), icône `cloud_download_outlined` si `notDownloaded`, rien sinon. Tap dossier : `push` vers le sous-dossier. Tap fichier : `controller.open(entry)` sur l'instance `DocumentsPreviewController(entry.path)` de cette ligne ; ignoré pendant que le contrôleur est en vol.

Suppression (lot 3) : chaque ligne de fichier est enveloppée dans un `Dismissible` (`key: ValueKey(entry.path)`, `direction: endToStart`, fond `AppColors.error` avec icône `delete_outline` alignée à droite), sur le modèle de `EventTile`. `confirmDismiss` ouvre un `AlertDialog` : titre `documentsDeleteTitle`, corps `documentsDeleteBody(entry.name)`, boutons `actionCancel` et `actionDelete` (rouge). Annuler renvoie `false` : la ligne se remet en place, rien n'est appelé. Confirmer renvoie `false` aussi (la ligne ne se retire pas d'elle-même : c'est le flux qui la fera disparaître) puis appelle `DocumentsDeleteController(folderPath).delete(entry.path)`. Au retour de la boîte de dialogue, si le widget a été démonté entre-temps (`context.mounted` faux : fichier supprimé par l'autre parent, accès perdu), il renvoie `false` sans rien supprimer ni toucher à `ref`. Le widget `ref.watch` le contrôleur de suppression du dossier (ce qui le garde vivant pendant l'`await`) et, tant qu'une suppression est en vol, désactive le glissement (`DismissDirection.none`) sur toutes les lignes de ce dossier. Les lignes de dossier ne sont pas dans un `Dismissible`.

Bouton flottant `+` (`DocumentsAddButton`) : affiché dès que le provider a une valeur (y compris pendant un rechargement) et n'est pas en erreur, absent sur `AsyncError` et pendant le tout premier chargement. `showModalBottomSheet` avec deux `ListTile` : `documentsActionScan` (icône `document_scanner`) et `documentsActionImport` (icône `upload_file`). Chacun ferme la feuille puis appelle `DocumentsWriteController(path).scan()` ou `.importFile()`. Pendant l'action, le bouton affiche un indicateur et est désactivé. Après une écriture réussie, la liste n'est pas invalidée : le flux natif reliste le dossier et le nouveau document apparaît de lui-même.

Erreurs de lecture (aperçu, `DocumentsPreviewController`) via `ref.listen` sur la tuile : `io` → `SnackBar` `documentsErrorNotDownloaded` ; `noFolder`/`accessDenied` → invalide `documentsFolderProvider(path)` pour afficher la vue « accès perdu » ; `cancelled` est déjà absorbé par le contrôleur (défense en profondeur côté tuile).

Erreurs d'écriture (scan, import, `DocumentsWriteController`) via `ref.listen` sur la page : `io` → `SnackBar` `documentsErrorWrite` (message dédié à l'écriture, distinct de `documentsErrorIo` que renverrait `failureMessage()`) ; `noFolder`/`accessDenied` → invalide `documentsFolderProvider(path)` ; `cancelled` : ignoré.

Erreurs de suppression (`DocumentsDeleteController`, lot 3) via `ref.listen` sur la page : `io` → `SnackBar` `documentsErrorDelete` ; `noFolder`/`accessDenied` → invalide `documentsFolderProvider(path)` ; autre → `failureMessage()`.

Erreurs d'ouverture dans Fichiers (`DocumentsOpenInFilesController`, lot 3) via `ref.listen` sur le bouton : `noFolder`/`accessDenied` → invalide `documentsFolderProvider(path)`, ce qui affiche la vue « accès perdu » (et retire le bouton) ; toute autre erreur → `SnackBar` `documentsErrorOpenInFiles`.

### Réglages

`DocumentsRootSection` dans `HouseholdSection`, après le code du foyer. `switch` sur `documentsRootProvider` :

- Sans dossier : un `ListTile` (icône + `settingsDocumentsNone`) suivi d'un bouton `documentsCardPick` *en dessous*, pas en `trailing` du `ListTile`. Un bouton en `trailing` était initialement prévu, mais son texte débordait à la largeur d'un iPhone standard (375 pt) ; la disposition verticale (`Column`) évite le débordement.
- Avec dossier : `ListTile` titre `settingsDocumentsFolder`, sous-titre `root.name`, et deux `TextButton` sous la ligne : `settingsDocumentsChange` (appelle `pick()`) et `settingsDocumentsForget`, en rouge (`AppColors.error`), qui ouvre un `AlertDialog` de confirmation `settingsDocumentsForgetConfirm` avant d'appeler `forget()`.
- `AsyncLoading` (pendant `pick()`/`forget()`) : `LinearProgressIndicator` à la place de la ligne.

Comme pour la carte et la vue « accès perdu », `pick()`/`forget()` renvoient un `Either` que le widget affiche lui-même dans une `SnackBar` via `failureMessage()`, `ScaffoldMessenger` et `S` capturés avant l'`await`.

### Clés l10n (`app_fr.arb`)

`documentsCardTitle` « Documents », `documentsCardEmptyBody` « Retrouvez vos ordonnances et documents », `documentsCardPick` « Choisir le dossier partagé », `documentsEmptyFolder` « Aucun document dans ce dossier », `documentsLostAccessBody` « Colette n'a plus accès au dossier », `documentsActionScan` « Scanner un document », `documentsActionImport` « Importer un fichier », `documentsErrorNotDownloaded` « Ce document n'est pas encore téléchargé sur cet iPhone », `documentsErrorWrite` « Impossible d'enregistrer le document », `documentsErrorIo` « Impossible d'accéder à ce document », `documentsErrorAccess` « Colette n'a pas accès à ce dossier », `settingsDocumentsNone` « Aucun dossier choisi », `settingsDocumentsFolder` « Dossier documents », `settingsDocumentsChange` « Changer de dossier », `settingsDocumentsForget` « Oublier le dossier », `settingsDocumentsForgetConfirm` « Colette n'affichera plus ce dossier. Vos fichiers ne sont pas supprimés. ». Lot 3 : `documentsDeleteTitle` « Supprimer ce document ? », `documentsDeleteBody` « {name} restera trente jours dans « Récemment supprimés » de l'app Fichiers. » (paramètre `name`), `documentsErrorDelete` « Impossible de supprimer ce document », `documentsOpenInFiles` « Ouvrir dans Fichiers », `documentsErrorOpenInFiles` « Impossible d'ouvrir Fichiers ». Les boutons de la confirmation réutilisent `actionCancel` et `actionDelete`.

Clair et sombre : couleurs uniquement via `AppColors`, aucune nouvelle couleur attendue.

## 8. Tests

- **Domaine** (purs) : `sortDocumentEntries` (dossiers avant fichiers, tri par nom insensible à la casse, fichiers par date décroissante puis nom) ; `buildScanFileName` avec une date fixe → `Scan 22-09-2026 14h32.pdf`.
- **Data** : `NativeDocumentsRepository` avec `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`. Un test par méthode (arguments transmis, résultat mappé), un test par code d'erreur (`noFolder`, `accessDenied`, `cancelled`, `io`, code inconnu → `UnknownFailure`), `DocumentEntryDto.fromMap` avec les trois statuts et un `modifiedAt` en ms ; lot 3 : `downloadProgress` présent, absent (`null`), et borné entre 0 et 1. `NativeDocumentsRepository.watch` avec `openFolderStream` mocké (il renvoie le nom d'un canal de test) et `setMockStreamHandler` (`MockStreamHandler`) sur ce canal : deux listes successives reçues en `Right`, erreur de plateforme convertie en `Left` puis flux terminé, échec de `openFolderStream` converti en `Left`, désabonnement propagé (`onCancel` appelé), y compris quand il survient pendant `openFolderStream`. Un test par nouvelle méthode (`download`, `delete`, `openInFiles`) et par code d'erreur.
- **Présentation** (`pumpApp` + `mocktail`, pas de `FakeDocumentsRepository` dédié) : `MockDocumentsRepository` (`test/helpers/documents_repository_override.dart`, avec un override par défaut `documentsRepositoryOverride()`) et `test/helpers/colette_app_overrides.dart` (overrides pour monter `ColetteApp` entière avec le routeur réel, réutilisés par les autres features). `pumpApp(viewSize:)` fixe la taille de la vue de test ; la section Réglages sans dossier est testée à la largeur d'un iPhone (375×812) pour couvrir le débordement corrigé. Couverture : carte sans dossier puis avec dossier ; tap sur « Choisir » appelle `pickRootFolder` ; page avec liste triée ; tap sur un dossier pousse le sous-dossier ; état vide ; état accès perdu sur `accessDenied` ; tap fichier appelle `preview` ; menu « + » appelle `scan` avec le nom attendu via `FixedClock` (depuis le lot 3, sans invalider la liste : `watch` appelé une seule fois) ; `cancelled` n'affiche aucune `SnackBar` ; `io` affiche la bonne `SnackBar` (`documentsErrorWrite` en écriture, `documentsErrorNotDownloaded` en aperçu) ; section Réglages, oubli avec confirmation. Lot 3, avec un `StreamController<Either<Failure, List<DocumentEntry>>>` par chemin exposé par le mock (`when(() => repo.watch(path)).thenAnswer((_) => controller.stream)`) : provider de dossier trié à chaque événement, `AsyncError` sur `Left`, invalidation qui réabonne (`watch` appelé deux fois) ; contrôleur d'aperçu : entrée `downloaded` → `preview` direct sans `download` ; entrée nuage → `download` puis `preview` quand le flux passe l'entrée à `downloaded` ; retour à `notDownloaded` → `AsyncError(io)` et `SnackBar` `documentsErrorNotDownloaded` ; `preview` répondant `cancelled` → retour au repos sans `SnackBar` ; tuile : indicateur avec valeur quand `downloadProgress` est connu, indéterminé sinon, icône nuage si `notDownloaded` ; glissement puis « Annuler » → ligne conservée, `delete` jamais appelé ; glissement puis « Supprimer » → `delete(path)` appelé ; une ligne de dossier n'a pas de `Dismissible` ; page : bouton Fichiers présent avec liste et liste vide, absent en accès perdu, tap → `openInFiles(path)` ; `SnackBar` `documentsErrorDelete` et `documentsErrorOpenInFiles` sur `io`. La page Documents a en plus un test monté sur le routeur réel de l'app (`ColetteApp` + `coletteAppOverrides`), pas seulement un `GoRouter` de test minimal, pour couvrir la route imbriquée telle qu'elle est réellement déclarée.
- **Swift** : pas de test automatisé. Liste de contrôle manuelle sur un iPhone réel avec le dossier partagé :
  1. Choisir le dossier, vérifier le nom sur la carte.
  2. Lister la racine et un sous-dossier, vérifier le tri.
  3. Ouvrir un fichier déjà téléchargé, puis un fichier avec l'icône nuage.
  4. Scanner deux pages, vérifier le PDF dans Fichiers sur les deux iPhones.
  5. Importer un PDF depuis Mail, puis le même une seconde fois : suffixe `(2)`.
  6. Tuer et relancer l'app : le dossier est toujours accessible.
  7. Renommer le dossier dans Fichiers : l'accès tient (bookmark), le nom affiché suit après « Changer de dossier ».
  8. Supprimer le dossier : vue « accès perdu » (`accessDenied`), distincte de l'état « aucun dossier choisi » (`noFolder`) ; re-choix fonctionnel.
  9. Mode avion : listage OK. (Aperçu d'un fichier nuage : depuis le lot 3, voir le point 26.)
  10. Chevauchement : lancer l'aperçu d'un fichier nuage puis, pendant le téléchargement, taper une deuxième ligne — pas d'indicateur de chargement resté bloqué sur la première ligne.
  11. Scanner 6 pages ou plus : pas de gel de l'UI pendant le rendu du PDF.
  12. Importer un fichier volumineux, puis le réimporter une seconde fois : le dossier `tmp/` de l'app ne grossit pas (le fichier `asCopy` est bien supprimé après chaque copie).
  13. Scanner une page au format paysage : rendue en A4 paysage dans le PDF, sans étirement.
  14. Annuler le scanner sans avoir pris de photo : pas de PDF vide créé, aucune erreur affichée.
  15. Présenter un scan pendant qu'un aperçu est déjà ouvert : le second est refusé (`cancelled`), le premier n'est pas perturbé.
  16. Relancer `ruby ios/scripts/add_documents_sources.rb` deux fois de suite : la seconde exécution ne réajoute rien (silencieuse, pas d'entrée dupliquée dans `Runner.xcodeproj`).
  17. (lot 3) Taper un fichier nuage volumineux : la ligne montre une progression qui avance, puis l'aperçu s'ouvre seul à la fin, sans second tap ni message.
  18. (lot 3) Lancer deux fichiers nuage l'un après l'autre : les deux progressent en parallèle ; le premier terminé s'ouvre ; le second, terminé pendant que l'aperçu est affiché, ne s'ouvre pas mais perd son icône nuage ; le fermer puis taper le second l'ouvre aussitôt.
  19. (lot 3) Juste après avoir choisi le dossier, les indicateurs de synchronisation en arrière-plan disparaissent d'eux-mêmes sans tirer-pour-rafraîchir.
  20. (lot 3) Glisser un fichier, annuler : la ligne revient. Glisser, confirmer : la ligne disparaît, et le fichier est dans « Récemment supprimés » de Fichiers sur les deux iPhones. Supprimer aussi un fichier encore non téléchargé (placeholder) : la ligne disparaît de même. Pour chacun, vérifier « Récemment supprimés » sur les deux iPhones et noter si le fichier y est : c'est le seul indice de la voie suivie (`trashItem`, ou repli `removeItem` s'il n'y est pas).
  21. (lot 3) Bouton Fichiers depuis la racine puis depuis un sous-dossier : Fichiers s'ouvre sur le bon dossier ; retour dans Colette, la liste est toujours là.
  22. (lot 3) Créer un fichier dans le dossier depuis l'autre iPhone : il apparaît dans la liste de Colette sans rafraîchir (si la requête de métadonnées fonctionne sur le dossier partagé ; sinon, il apparaît après tirer-pour-rafraîchir, et c'est à noter dans la section 11). Brancher l'iPhone et filtrer la Console macOS sur `DocumentsFolderWatcher` : nombre de résultats iCloud à la fin de la collecte, ou échec du démarrage de la requête.
  23. (lot 3) Dossier dont le nom contient un accent (ex. « Bébé ») : la liste se met à jour en direct et la progression s'affiche (prédicat de la requête de métadonnées sur un chemin accentué).
  24. (lot 3) Bouton Fichiers sur un sous-dossier du dossier partagé : Fichiers s'ouvre bien sur ce sous-dossier (forme `/private/var/…` de l'URL).
  25. (lot 3) Gros fichier nuage ouvert depuis Colette : à la fin du téléchargement, l'aperçu s'ouvre sans passer par « pas encore téléchargé ».
  26. (lot 3) Mode avion, tap sur un fichier nuage : la ligne montre un indicateur ; désactiver le mode avion : le téléchargement reprend et l'aperçu s'ouvre. (Sans réseau, iCloud peut ne jamais signaler « en téléchargement » : la ligne reste alors en attente sans message tant qu'on ne quitte pas la page — à noter si observé, voir section 11.)

Limite du simulateur : `VNDocumentCameraViewController` n'est pas disponible sur le simulateur iOS (le scan ne peut pas y être testé), et le simulateur ne matérialise pas de vrais placeholders iCloud téléchargeables à la demande — les points 3, 4, 9, 10, 11 et 17 à 26 de la liste ci-dessus demandent un iPhone réel.

## 9. Livraison

- **Lot 1, lecture** : failures, entités, repository, pont Swift (`pickRootFolder`, `rootFolder`, `forgetRootFolder`, `list`, `preview`), providers, carte, page, section Réglages, l10n, tests.
- **Lot 2, écriture** : `scan`, `importFile`, `buildScanFileName`, bouton `+`, `NSCameraUsageDescription`, tests associés.

- **Lot 3, suivi en direct, suppression, Fichiers** (2026-09-23) : canaux d'événements de dossier (`openFolderStream`, un par abonnement) et `DocumentsFolderWatcher`, `download` découplé de `preview`, `delete`, `openInFiles`, `downloadProgress`, `watch()` à la place de `list()`, contrôleurs d'aperçu (télécharger puis ouvrir), de suppression et d'ouverture, `Dismissible`, bouton d'`AppBar`, l10n, tests, liste de contrôle 17 à 26.

Le lot 1 est livrable seul. Le lot 3 se livre sur la même branche que les lots 1 et 2, avant leur fusion.

## 10. Écarts par rapport à la spec initiale

1. **Deux contrôleurs plutôt qu'un `DocumentsController` unique.** `DocumentsPreviewController(path)` (famille par chemin de fichier) et `DocumentsWriteController(folderPath)` (famille par dossier) : chaque ligne de la liste suit son propre aperçu, et chaque page (racine ou sous-dossier poussé) son propre scan/import, sans état partagé ni interférence entre lignes ou entre pages.
2. **`retry: noRetry` sur `documentsFolderProvider` et `DocumentsRoot`.** Sans cette politique, Riverpod 3 relance jusqu'à dix fois un `build` qui lève tout en affichant `AsyncLoading`, ce qui masquerait une `DocumentsFailure` (dossier perdu, par exemple) derrière un spinner pendant plusieurs secondes au lieu de remonter l'erreur immédiatement.
3. **`DocumentsRoot.pick()` et `.forget()` renvoient un `Either<Failure, T>` plutôt que de basculer silencieusement en `AsyncError`.** Les widgets appelants (carte, section Réglages, vue « accès perdu ») affichent eux-mêmes la `SnackBar` d'échec avec `failureMessage()`, en capturant `ScaffoldMessenger` et `S` avant l'`await` puisque `pick()`/`forget()` passent par `AsyncLoading` et peuvent démonter le widget appelant.
4. **Le mapping `PlatformException → DocumentsFailure` vit dans `NativeDocumentsRepository` (méthode privée `_call`), pas dans `guard()` de `core/result`.** Objectif : ne pas coupler le code générique de `core` aux codes du canal `colette/documents`. `DocumentsFailure` a en plus l'égalité par valeur, nécessaire pour comparer des `Either` dans les tests.
5. **`documentsErrorIo` est une clé l10n à part**, distincte de `documentsErrorWrite` et `documentsErrorNotDownloaded` déjà prévues. `failureMessage()` mappe `io` sur `documentsErrorIo` (message générique), tandis que la page Documents et la tuile de fichier affichent directement leur propre message plus précis pour une écriture ou un aperçu en échec.
6. **La section Réglages sans dossier a été changée de disposition.** Le bouton « Choisir le dossier partagé » prévu en `trailing` d'un `ListTile` débordait à la largeur d'un iPhone standard (375 pt) ; il est passé sous le `ListTile`, dans une `Column`.
7. **Opérations concurrentes explicitement refusées côté Swift.** Un verrou global unique dans `DocumentsPlugin` couvre les quatre opérations système et l'attente de téléchargement d'un aperçu : toute deuxième opération, même d'un autre type, échoue avec `cancelled` (ignoré par l'UI) au lieu de se comporter de façon indéfinie — sans lui, un scan pouvait présenter la caméra pendant qu'un aperçu attendait encore son téléchargement, puis Quick Look s'ouvrait par-dessus. Ce n'était pas détaillé dans la version initiale de la spec. Depuis le lot 3, le verrou ne couvre plus l'attente de téléchargement, qui n'existe plus côté Swift.
8. **Les sources Swift sont enregistrées dans `Runner.xcodeproj` par un script Ruby idempotent** (`ios/scripts/add_documents_sources.rb`, gem `xcodeproj`) plutôt qu'à la main dans Xcode, pour que l'ajout de fichiers reste reproductible et scriptable.

## 11. Lot 3 : pourquoi, et alternatives écartées

Premiers essais sur iPhone (2026-09-23), dossier partagé par l'autre compte Apple : l'arborescence, le scan et l'import fonctionnent. Deux défauts ressentis :

- **Téléchargement long au premier tap.** `preview` lançait le téléchargement puis sondait le fichier toutes les 0,5 s pendant 30 s au plus, sans rien afficher d'autre qu'un spinner. Un dossier partagé passe par les serveurs de partage, plus lents ; au-delà de 30 s l'app affichait « pas encore téléchargé » alors que le téléchargement continuait, et le tap suivant ouvrait le fichier. Pendant l'attente, le verrou global bloquait tout autre aperçu, scan ou import.
- **Indicateurs qui reviennent.** La liste était une photo prise au listage. Après l'installation, iOS synchronise le dossier en arrière-plan : beaucoup de fichiers sont « en téléchargement » au moment du listage, restent affichés ainsi jusqu'au prochain rafraîchissement, et un fichier téléchargé par l'aperçu gardait son icône nuage.

Cause commune : aucun suivi en direct de l'état iCloud. Le lot 3 remplace la photo par un flux natif alimenté par `NSMetadataQuery`, découple le téléchargement de l'aperçu, et en profite pour ajouter la suppression et l'ouverture dans Fichiers demandées au même moment.

Alternatives écartées :

- **Correctif minimal** : délai porté à deux minutes, attente par lecture coordonnée (`NSFileCoordinator`), relistage à la fermeture de chaque aperçu. Pas de pourcentage, indicateurs de synchronisation toujours figés, verrou toujours tenu pendant l'attente.
- **Relistage périodique** : relister toutes les trois secondes tant qu'un téléchargement demandé via `download` pour ce dossier n'est pas terminé (ou qu'une ligne est en téléchargement ; sans requête de métadonnées, un placeholder ne passe jamais par `downloading`, la condition sur les seuls téléchargements demandés est donc indispensable). Simple, mais un listage complet du dossier à chaque tour, pas de pourcentage, et pas de mise à jour quand l'autre parent ajoute un fichier. Reste le plan de repli si `NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope` ne remonte rien sur le dossier partagé (point 22 de la liste de contrôle) : dans ce cas, `DocumentsFolderWatcher` relisterait sur minuterie tant qu'un fichier est `downloading`, sans changer le contrat du canal ni l'UI.

Décisions d'interface prises avec Maxence : suppression par glissement vers la gauche avec confirmation, fichiers seulement (jamais un dossier partagé entier ; levé au lot 4 pour les sous-dossiers) ; bouton Fichiers menant au dossier affiché, pas toujours à la racine.

Points ouverts après revue (2026-09-23). Le code est relu et testé côté Flutter, mais quelques comportements d'iOS ne se tranchent que sur iPhone réel, avec le dossier partagé :

- **Portée de la requête sur un dossier partagé** (point 22) : si `NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope` ne remonte rien (diagnostic `os_log` à zéro résultat), appliquer le plan de repli ci-dessus (relistage sur minuterie).
- **`trashItem` ou `removeItem`** (point 20) : on ne sait pas encore si iOS accepte la corbeille pour un fichier du dossier partagé ; seule la présence du fichier dans « Récemment supprimés » le dira. Le texte de confirmation (`documentsDeleteBody`) promet ce passage : à reformuler si le repli est la voie suivie.
- **`/private/var` dans `shareddocuments://`** (point 24) : Fichiers doit accepter la forme du chemin donnée par le bookmark ; sinon, retirer le préfixe `/private` avant de construire l'URL.
- **Accent dans le prédicat** (point 23) : le `BEGINSWITH` doit correspondre sur un chemin accentué ; en cas d'échec, comparer des chemins normalisés (NFC/NFD) en code plutôt que dans le prédicat.
- **Attente sans délai quand iCloud ne signale jamais de téléchargement** (point 26) : la ligne reste en attente sans message tant qu'on ne quitte pas la page. Suite possible si c'est observé : réactiver le tap pendant l'attente (un second tap relance `download`), ou ajouter un délai d'expiration généreux côté Flutter, déclenché seulement tant qu'aucun `downloading` n'a été vu.

## 12. Lot 4 : gestion des dossiers (2026-09-24)

Demande de Maxence : gérer les dossiers depuis Colette. Périmètre retenu : créer, renommer, déplacer, supprimer (dossiers non vides compris).

- **Créer** : entrée « Nouveau dossier » du menu « + », dans le dossier affiché. Nom déjà pris : suffixe « (2) » en fin de nom (pas d'extension découpée pour un dossier).
- **Appui long** sur une ligne (fichier ou dossier) : feuille Renommer / Déplacer / Supprimer. Le glissement vers la gauche supprime aussi les dossiers ; la confirmation d'un dossier annonce la suppression de tout son contenu (corbeille iCloud quand iOS le permet). La racine choisie ne peut être ni supprimée, ni renommée, ni déplacée.
- **Renommer** : dialogue prérempli ; pour un fichier, seule la base est éditable, l'extension est affichée en suffixe et conservée. Nom déjà pris : erreur `nameTaken` (« Un élément porte déjà ce nom »), jamais de suffixe silencieux ; un simple changement de casse est permis.
- **Déplacer** : page plein écran `DocumentsMovePage` qui parcourt les sous-dossiers depuis la racine (jamais au-delà : le bookmark ne couvre qu'elle), avec retour d'un niveau, création de dossier sur place et bouton « Déplacer ici » inactif sur le dossier actuel, l'élément lui-même ou l'un de ses descendants (`canMoveInto`, vérifié aussi côté Swift). Nom pris dans la destination : suffixe « (2) ».
- **Validation des noms** (`validateEntryName`) : sans espaces autour, non vide, sans `/`, sans point initial. Vérifiée à la saisie (bouton inactif, message sous le champ), dans le contrôleur et côté Swift.
- **Canal** : `createFolder {path, name}`, `rename {path, name}`, `move {path, destination}` renvoient `{name}` (nom final) ; nouveau code d'erreur `nameTaken`. Déplacement et renommage passent par `NSFileCoordinator` (`.forMoving` / `.forReplacing`, `item(at:willMoveTo:)` / `didMoveTo`) ; un placeholder `.x.icloud` reste un placeholder à l'arrivée. Après succès, Swift reliste les flux du dossier source et, pour un déplacement, de la destination.
- **Flutter** : `DocumentsManageController(folderPath)` remplace `DocumentsDeleteController` et porte les quatre opérations ; les erreurs sont affichées par la page au premier plan seulement (`showDocumentsManageError`), pour qu'une création échouée depuis la page de déplacement ne produise pas deux SnackBars.

À vérifier sur iPhone réel : renommage et déplacement d'un fichier non téléchargé, suppression d'un dossier non vide (présence dans « Récemment supprimés »), propagation chez l'autre parent.
