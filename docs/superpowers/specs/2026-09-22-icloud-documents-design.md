# Colette — Documents du dossier iCloud partagé

Date : 2026-09-22. Complète la spec v1 (`2026-09-21-colette-v1-design.md`).

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
| Listage | Sous-dossiers d'abord, triés par nom (insensible à la casse, `compareTo` sur la version minuscule). Puis fichiers par date de modification décroissante, nom croissant à égalité. Les fichiers cachés (nom commençant par `.`) sont exclus, sauf les placeholders iCloud, normalisés (voir Données). La lecture du dossier et des métadonnées s'exécute hors du thread principal (`DispatchQueue.global(qos: .userInitiated)`), la portée sécurisée restant ouverte jusqu'à la fin du listage ; la réponse au canal revient sur le thread principal une fois la portée refermée. |
| Placeholders | Si `x.pdf` et son placeholder `.x.pdf.icloud` existent tous les deux (téléchargement en cours au moment du listage), une seule entrée est renvoyée pour le chemin `x.pdf` : le fichier réel prime sur le placeholder. |
| Aperçu | `QLPreviewController` natif. Si le fichier n'est pas téléchargé, Swift lance `startDownloadingUbiquitousItem` et attend le statut `current`, avec un délai maximal de 30 secondes. Au-delà : `io`. |
| Scan | `VNDocumentCameraViewController`. Les pages sont rendues dans un PDF unique, nommé `Scan {jj}-{MM}-{aaaa} {HH}h{mm}.pdf` avec l'horloge de l'app (`clockProvider`), écrit dans le dossier courant. |
| Import | `UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)`. Le fichier est copié dans le dossier courant sous son nom d'origine. |
| Collision de nom | Résolue en Swift juste avant l'écriture : `nom (2).ext`, `nom (3).ext`, etc. |
| Écriture | Toujours via `NSFileCoordinator.coordinate(writingItemAt:)` dans la portée de `startAccessingSecurityScopedResource`. Le rendu du PDF et la coordination de fichier s'exécutent hors du thread principal (`DispatchQueue.global(qos: .userInitiated)`) ; la réponse au canal revient sur le thread principal une fois la portée refermée. Le fichier temporaire de l'import (copie `asCopy` du sélecteur système) est supprimé juste après la copie dans le dossier iCloud. Les pages scannées sont mises en page sur une page A4, portrait ou paysage selon l'orientation de l'image, avec un centrage qui conserve le rapport d'aspect (aucun étirement). Le `fileName` d'un scan (et le nom retenu pour une collision) contenant `/`, valant `.` ou `..`, ou vide, est refusé avec `accessDenied`. Un scan sans page (annulé après la première photo, ou toutes les pages supprimées avant validation) échoue avec `cancelled`, pas avec un PDF vide. |
| Opérations concurrentes | Un seul verrou global dans `DocumentsPlugin` couvre les quatre opérations système (`pickRootFolder`, `preview`, `scan`, `importFile`), attente du téléchargement iCloud d'un aperçu comprise — donc avant même qu'un écran soit présenté. Toute deuxième opération, du même type ou d'un autre, est refusée immédiatement avec `cancelled` sans toucher au presenter ni au store ; l'UI l'ignore comme n'importe quelle annulation, sans perturber l'opération en cours. Le verrou est libéré sur chaque fin possible (succès, échec, annulation, présentation impossible), sans délai d'expiration : il repose sur les complétions UIKit et les délégués système, toujours appelés ; un délai qui relâcherait le verrou pendant qu'un écran système est encore affiché réintroduirait les présentations superposées. Les gardes par écran du presenter restent en seconde ligne. `list`, `rootFolder` et `forgetRootFolder` ne prennent pas le verrou. |
| Présentation | Les écrans système (sélecteurs, `QLPreviewController`, scanner) sont présentés sur le contrôleur au sommet de la pile de présentation de la scène `foregroundActive` (ou, à défaut, la première scène avec une fenêtre clé). Si la présentation n'aboutit pas (aucune scène active, vue non prête), l'opération échoue avec `io`, pas silencieusement. |
| Hors ligne | Le listage fonctionne (iCloud garde les métadonnées). Un fichier non téléchargé reste visible avec l'icône nuage ; son aperçu échoue avec `io` et l'UI affiche « Ce document n'est pas encore téléchargé sur cet iPhone ». Aucun état Flutter persisté. |
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

Un fichier non téléchargé apparaît dans `FileManager.contentsOfDirectory` sous la forme `.{nom}.{ext}.icloud`. Swift le normalise : `name` sans le `.` initial ni le suffixe `.icloud`, `path` construit avec ce nom normalisé, `downloadStatus = notDownloaded`. Pour les autres fichiers, le statut vient de `URLResourceValues.ubiquitousItemDownloadingStatus` (`current` → `downloaded`, sinon `downloading` si `ubiquitousItemIsDownloading`, sinon `notDownloaded`). Un fichier hors iCloud (dossier local choisi) est `downloaded`.

Avant tout accès à un fichier par son chemin relatif, Swift tente d'abord `{dossier}/{nom}`, puis le placeholder `{dossier}/.{nom}.icloud`.

## 5. Contrat du canal natif `colette/documents`

`MethodChannel` nommé `colette/documents`. Chaque méthode renvoie un résultat ou lève une `PlatformException` dont `code` vaut `noFolder`, `accessDenied`, `cancelled` ou `io`. Tout autre code est mappé sur `UnknownFailure`.

| Méthode | Arguments | Retour |
| --- | --- | --- |
| `pickRootFolder` | aucun | `{name: String}` ; `cancelled` si annulé |
| `rootFolder` | aucun | `{name: String}` ou `null` |
| `forgetRootFolder` | aucun | `null` |
| `list` | `{path: String}` | `List<Map>` : `{name, path, isDirectory, size, modifiedAt (ms epoch UTC), downloadStatus ('downloaded' \| 'downloading' \| 'notDownloaded')}` |
| `preview` | `{path: String}` | `null`, une fois l'aperçu fermé |
| `scan` | `{path: String, fileName: String}` | `{name: String}` du PDF créé (après résolution de collision) ; `cancelled` |
| `importFile` | `{path: String}` | `{name: String}` du fichier copié ; `cancelled` |

Côté Swift : `ios/Runner/Documents/DocumentsPlugin.swift` (enregistrement du canal, dispatch), `DocumentsStore.swift` (bookmark, résolution, portée sécurisée), `DocumentsLister.swift` (listage, normalisation des placeholders), `DocumentsWriter.swift` (PDF depuis les images du scan, copie, collision), `DocumentsPresenter.swift` (sélecteurs, `QLPreviewController`, `VNDocumentCameraViewController`, présentés depuis le contrôleur au sommet de la pile de présentation de la scène active, pas depuis un `rootViewController` fixe — voir section 3, « Présentation »), `DocumentsError.swift` (mapping des raisons vers `FlutterError`). Enregistré dans `AppDelegate.didInitializeImplicitFlutterEngine`. Si le `registrar` du plugin est indisponible au démarrage, `DocumentsPlugin.register` renonce sans planter et journalise via `os_log` (canal non enregistré).

`Info.plist` : ajout de `NSCameraUsageDescription` (« Colette utilise l'appareil photo pour scanner vos documents. »). Aucun entitlement iCloud nécessaire : le sélecteur de dossier suffit.

Les six fichiers Swift (`DocumentsPlugin.swift`, `DocumentsStore.swift`, `DocumentsLister.swift`, `DocumentsWriter.swift`, `DocumentsPresenter.swift`, `DocumentsError.swift`) sont référencés dans `Runner.xcodeproj` par `ios/scripts/add_documents_sources.rb` (gem `xcodeproj`, livrée avec CocoaPods), plutôt qu'à la main dans Xcode : le script ajoute le groupe et les fichiers manquants à la cible `Runner`, et ne fait rien s'ils y sont déjà (idempotent, vérifié en le relançant deux fois de suite).

## 6. Architecture Flutter

```
lib/features/documents/
  domain/
    entities/document_root.dart, document_entry.dart, download_status.dart
    repositories/documents_repository.dart
    use_cases/sort_document_entries.dart      dossiers puis fichiers, règle de la section 3
    use_cases/build_scan_file_name.dart       « Scan jj-MM-aaaa HHhmm.pdf » depuis un DateTime (préfixe « Scan » fixe, le domaine n'a pas de l10n)
  data/
    dtos/document_entry_dto.dart              fromMap depuis la map du canal
    native_documents_repository.dart          MethodChannel + mapping PlatformException → Failure
  presentation/
    providers/documents_providers.dart        documentsRepositoryProvider (keepAlive),
                                              documentsFolderProvider(path) (autoDispose, retry: noRetry)
    providers/documents_root.dart             DocumentsRoot : FutureOr<DocumentRoot?>, pick(), forget()
    providers/documents_preview_controller.dart  DocumentsPreviewController(path) : famille autoDispose, preview()
    providers/documents_write_controller.dart    DocumentsWriteController(folderPath) : famille autoDispose, scan(), importFile()
    pages/documents_page.dart
    widgets/documents_card.dart               carte sur Aujourd'hui
    widgets/document_entry_tile.dart
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
  Future<Either<Failure, List<DocumentEntry>>> list(String path);
  Future<Either<Failure, void>> preview(String path);
  Future<Either<Failure, String>> scan({required String folderPath, required String fileName});
  Future<Either<Failure, String>> importFile({required String folderPath});
}
```

`NativeDocumentsRepository` (constructeur `const`) reçoit le `MethodChannel` en constructeur (injectable en test). Chaque appel passe par une méthode privée `_call`, calquée sur `guard()` mais locale au repository : elle convertit un `PlatformException` en `DocumentsFailure` selon son `code` (`noFolder`, `accessDenied`, `cancelled`, `io`), et tout autre code ou exception en `UnknownFailure` avec un log. Le mapping n'est volontairement pas fait par `guard()` de `core/result`, pour ne pas coupler `core` aux codes du canal `colette/documents`.

### Providers

- `documentsRepositoryProvider` : `keepAlive`, construit `NativeDocumentsRepository(const MethodChannel('colette/documents'))`.
- `DocumentsRoot` (`@Riverpod(keepAlive: true, retry: noRetry)`) : `build()` appelle `rootFolder()`. `pick()` : si un `build` initial ou un `pick`/`forget` précédent est encore en vol (`state.isLoading`), renvoie aussitôt `right(false)` sans toucher à l'état, pour qu'un résultat tardif ne l'écrase pas après coup. Sinon, passe en `AsyncLoading` puis appelle `pickRootFolder()`. Succès : `AsyncData(root)`, `right(true)`, invalide tous les `documentsFolderProvider`. Échec `cancelled` : restaure l'état précédent, `right(false)`. Autre échec : restaure aussi l'état précédent, `left(failure)` — c'est à l'appelant de l'afficher. `forget()` a la même garde de concurrence ; succès : `AsyncData(null)`, `right(null)`, invalide les `documentsFolderProvider` ; échec : restaure l'état précédent, `left(failure)`.
- `documentsFolderProvider(String path)` : `@Riverpod(retry: noRetry)` (`autoDispose` implicite), appelle `list(path)` puis `sortDocumentEntries`. Un `Left` est relancé en exception pour que l'UI le reçoive en `AsyncError`.
- `DocumentsPreviewController(String path)` (`@riverpod`, famille `autoDispose`, `FutureOr<void> build(path) {}`) : `preview()` appelle `repository.preview(path)` ; `cancelled` remet `AsyncData(null)` sans erreur, toute autre failure passe en `AsyncError`. Une instance par chemin de fichier : chaque ligne de la liste affiche son propre indicateur (`ref.watch(...).isLoading`) et écoute ses propres erreurs (`ref.listen`) sans affecter les autres lignes.
- `DocumentsWriteController(String folderPath)` (`@riverpod`, famille `autoDispose`, `FutureOr<void> build(folderPath) {}`) : `scan()` calcule le nom avec `clockProvider` et `buildScanFileName`, `importFile()` n'a pas de nom à calculer. Les deux passent par une méthode privée `_run` : `AsyncLoading`, puis sur succès `ref.invalidate(documentsFolderProvider(folderPath))` (uniquement en cas de succès, jamais après un échec) et `AsyncData(null)` ; `cancelled` → `AsyncData(null)` sans erreur ; autre échec → `AsyncError`. Famille par `folderPath` : la page racine et une sous-page poussée observent chacune leur propre instance, sans se déclencher mutuellement.

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

`AppBar` avec le nom du dossier courant (nom de la racine si `path` vide). `switch` sur `documentsFolderProvider(path)` :

- `AsyncData` vide (et sans rechargement en cours) : `EmptyState` avec `documentsEmptyFolder`.
- `AsyncData`, y compris un rafraîchissement en cours (`hasValue` reste vrai pendant un `AsyncLoading` avec `previousData`) : `ListView.builder` de `DocumentEntryTile`, dans un `RefreshIndicator` qui rafraîchit le provider. La liste actuelle reste affichée pendant le tirer-pour-rafraîchir et après une écriture (scan/import réussis invalident le provider), plutôt que de basculer sur le spinner. Si le rafraîchissement échoue, le provider passe en `AsyncError` et la page affiche la vue « accès perdu » ou le message générique à la place de la liste (les bras `AsyncError` précèdent les bras `hasValue`) ; le `try/catch` de `onRefresh` sert seulement à journaliser l'erreur (`log(..., name: 'colette')`) au lieu de la laisser fuir en exception non gérée depuis le `RefreshIndicator`.
- Aucune valeur encore reçue (premier chargement) : indicateur centré.
- `AsyncError(error: DocumentsFailure(reason: noFolder || accessDenied))` : `DocumentsLostAccessView` avec `documentsLostAccessBody` et un bouton `documentsCardPick` qui appelle `pick()` puis, en cas de succès, `context.go(AppRoutes.todayDocuments)` pour repartir de la racine.
- Autre `AsyncError` : `EmptyState` avec le message générique de `failureMessage`.

`EmptyState` a un slot `action` optionnel (`Widget?`, affiché sous le message) ; `DocumentsLostAccessView` l'utilise pour son bouton `documentsCardPick`.

`DocumentEntryTile` : icône `folder` pour un dossier, `picture_as_pdf` pour `.pdf`, `image` pour `.jpg`, `.jpeg`, `.png`, `.heic`, `insert_drive_file` sinon. Titre : `name`. Sous-titre : date de modification formatée `d MMM yyyy`, absente pour un dossier. Trailing : chevron pour un dossier, icône `cloud_download_outlined` si `notDownloaded`, indicateur circulaire si `downloading` ou si l'aperçu de cette ligne est en cours, rien sinon. Tap dossier : `push` vers le sous-dossier. Tap fichier : `controller.preview()` sur l'instance `DocumentsPreviewController(entry.path)` de cette ligne.

Bouton flottant `+` (`DocumentsAddButton`) : affiché dès que le provider a une valeur (y compris pendant un rechargement) et n'est pas en erreur, absent sur `AsyncError` et pendant le tout premier chargement. `showModalBottomSheet` avec deux `ListTile` : `documentsActionScan` (icône `document_scanner`) et `documentsActionImport` (icône `upload_file`). Chacun ferme la feuille puis appelle `DocumentsWriteController(path).scan()` ou `.importFile()`. Pendant l'action, le bouton affiche un indicateur et est désactivé.

Erreurs de lecture (aperçu, `DocumentsPreviewController`) via `ref.listen` sur la tuile : `io` → `SnackBar` `documentsErrorNotDownloaded` ; `noFolder`/`accessDenied` → invalide `documentsFolderProvider(path)` pour afficher la vue « accès perdu » ; `cancelled` est déjà absorbé par le contrôleur (défense en profondeur côté tuile).

Erreurs d'écriture (scan, import, `DocumentsWriteController`) via `ref.listen` sur la page : `io` → `SnackBar` `documentsErrorWrite` (message dédié à l'écriture, distinct de `documentsErrorIo` que renverrait `failureMessage()`) ; `noFolder`/`accessDenied` → invalide `documentsFolderProvider(path)` ; `cancelled` : ignoré.

### Réglages

`DocumentsRootSection` dans `HouseholdSection`, après le code du foyer. `switch` sur `documentsRootProvider` :

- Sans dossier : un `ListTile` (icône + `settingsDocumentsNone`) suivi d'un bouton `documentsCardPick` *en dessous*, pas en `trailing` du `ListTile`. Un bouton en `trailing` était initialement prévu, mais son texte débordait à la largeur d'un iPhone standard (375 pt) ; la disposition verticale (`Column`) évite le débordement.
- Avec dossier : `ListTile` titre `settingsDocumentsFolder`, sous-titre `root.name`, et deux `TextButton` sous la ligne : `settingsDocumentsChange` (appelle `pick()`) et `settingsDocumentsForget`, en rouge (`AppColors.error`), qui ouvre un `AlertDialog` de confirmation `settingsDocumentsForgetConfirm` avant d'appeler `forget()`.
- `AsyncLoading` (pendant `pick()`/`forget()`) : `LinearProgressIndicator` à la place de la ligne.

Comme pour la carte et la vue « accès perdu », `pick()`/`forget()` renvoient un `Either` que le widget affiche lui-même dans une `SnackBar` via `failureMessage()`, `ScaffoldMessenger` et `S` capturés avant l'`await`.

### Clés l10n (`app_fr.arb`)

`documentsCardTitle` « Documents », `documentsCardEmptyBody` « Retrouvez vos ordonnances et documents », `documentsCardPick` « Choisir le dossier partagé », `documentsEmptyFolder` « Aucun document dans ce dossier », `documentsLostAccessBody` « Colette n'a plus accès au dossier », `documentsActionScan` « Scanner un document », `documentsActionImport` « Importer un fichier », `documentsErrorNotDownloaded` « Ce document n'est pas encore téléchargé sur cet iPhone », `documentsErrorWrite` « Impossible d'enregistrer le document », `documentsErrorIo` « Impossible d'accéder à ce document », `documentsErrorAccess` « Colette n'a pas accès à ce dossier », `settingsDocumentsNone` « Aucun dossier choisi », `settingsDocumentsFolder` « Dossier documents », `settingsDocumentsChange` « Changer de dossier », `settingsDocumentsForget` « Oublier le dossier », `settingsDocumentsForgetConfirm` « Colette n'affichera plus ce dossier. Vos fichiers ne sont pas supprimés. ».

Clair et sombre : couleurs uniquement via `AppColors`, aucune nouvelle couleur attendue.

## 8. Tests

- **Domaine** (purs) : `sortDocumentEntries` (dossiers avant fichiers, tri par nom insensible à la casse, fichiers par date décroissante puis nom) ; `buildScanFileName` avec une date fixe → `Scan 22-09-2026 14h32.pdf`.
- **Data** : `NativeDocumentsRepository` avec `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`. Un test par méthode (arguments transmis, résultat mappé), un test par code d'erreur (`noFolder`, `accessDenied`, `cancelled`, `io`, code inconnu → `UnknownFailure`), `DocumentEntryDto.fromMap` avec les trois statuts et un `modifiedAt` en ms.
- **Présentation** (`pumpApp` + `mocktail`, pas de `FakeDocumentsRepository` dédié) : `MockDocumentsRepository` (`test/helpers/documents_repository_override.dart`, avec un override par défaut `documentsRepositoryOverride()`) et `test/helpers/colette_app_overrides.dart` (overrides pour monter `ColetteApp` entière avec le routeur réel, réutilisés par les autres features). `pumpApp(viewSize:)` fixe la taille de la vue de test ; la section Réglages sans dossier est testée à la largeur d'un iPhone (375×812) pour couvrir le débordement corrigé. Couverture : carte sans dossier puis avec dossier ; tap sur « Choisir » appelle `pickRootFolder` ; page avec liste triée ; tap sur un dossier pousse le sous-dossier ; état vide ; état accès perdu sur `accessDenied` ; tap fichier appelle `preview` ; menu « + » appelle `scan` avec le nom attendu via `FixedClock` puis invalide la liste ; `cancelled` n'affiche aucune `SnackBar` ; `io` affiche la bonne `SnackBar` (`documentsErrorWrite` en écriture, `documentsErrorNotDownloaded` en aperçu) ; section Réglages, oubli avec confirmation. La page Documents a en plus un test monté sur le routeur réel de l'app (`ColetteApp` + `coletteAppOverrides`), pas seulement un `GoRouter` de test minimal, pour couvrir la route imbriquée telle qu'elle est réellement déclarée.
- **Swift** : pas de test automatisé. Liste de contrôle manuelle sur un iPhone réel avec le dossier partagé :
  1. Choisir le dossier, vérifier le nom sur la carte.
  2. Lister la racine et un sous-dossier, vérifier le tri.
  3. Ouvrir un fichier déjà téléchargé, puis un fichier avec l'icône nuage.
  4. Scanner deux pages, vérifier le PDF dans Fichiers sur les deux iPhones.
  5. Importer un PDF depuis Mail, puis le même une seconde fois : suffixe `(2)`.
  6. Tuer et relancer l'app : le dossier est toujours accessible.
  7. Renommer le dossier dans Fichiers : l'accès tient (bookmark), le nom affiché suit après « Changer de dossier ».
  8. Supprimer le dossier : vue « accès perdu » (`accessDenied`), distincte de l'état « aucun dossier choisi » (`noFolder`) ; re-choix fonctionnel.
  9. Mode avion : listage OK, aperçu d'un fichier nuage → `SnackBar`.
  10. Chevauchement : lancer l'aperçu d'un fichier nuage puis, pendant le téléchargement, taper une deuxième ligne — pas d'indicateur de chargement resté bloqué sur la première ligne.
  11. Scanner 6 pages ou plus : pas de gel de l'UI pendant le rendu du PDF.
  12. Importer un fichier volumineux, puis le réimporter une seconde fois : le dossier `tmp/` de l'app ne grossit pas (le fichier `asCopy` est bien supprimé après chaque copie).
  13. Scanner une page au format paysage : rendue en A4 paysage dans le PDF, sans étirement.
  14. Annuler le scanner sans avoir pris de photo : pas de PDF vide créé, aucune erreur affichée.
  15. Présenter un scan pendant qu'un aperçu est déjà ouvert : le second est refusé (`cancelled`), le premier n'est pas perturbé.
  16. Relancer `ruby ios/scripts/add_documents_sources.rb` deux fois de suite : la seconde exécution ne réajoute rien (silencieuse, pas d'entrée dupliquée dans `Runner.xcodeproj`).

Limite du simulateur : `VNDocumentCameraViewController` n'est pas disponible sur le simulateur iOS (le scan ne peut pas y être testé), et le simulateur ne matérialise pas de vrais placeholders iCloud téléchargeables à la demande — les points 3, 4, 9, 10 et 11 de la liste ci-dessus demandent un iPhone réel.

## 9. Livraison

- **Lot 1, lecture** : failures, entités, repository, pont Swift (`pickRootFolder`, `rootFolder`, `forgetRootFolder`, `list`, `preview`), providers, carte, page, section Réglages, l10n, tests.
- **Lot 2, écriture** : `scan`, `importFile`, `buildScanFileName`, bouton `+`, `NSCameraUsageDescription`, tests associés.

Le lot 1 est livrable seul.

## 10. Écarts par rapport à la spec initiale

1. **Deux contrôleurs plutôt qu'un `DocumentsController` unique.** `DocumentsPreviewController(path)` (famille par chemin de fichier) et `DocumentsWriteController(folderPath)` (famille par dossier) : chaque ligne de la liste suit son propre aperçu, et chaque page (racine ou sous-dossier poussé) son propre scan/import, sans état partagé ni interférence entre lignes ou entre pages.
2. **`retry: noRetry` sur `documentsFolderProvider` et `DocumentsRoot`.** Sans cette politique, Riverpod 3 relance jusqu'à dix fois un `build` qui lève tout en affichant `AsyncLoading`, ce qui masquerait une `DocumentsFailure` (dossier perdu, par exemple) derrière un spinner pendant plusieurs secondes au lieu de remonter l'erreur immédiatement.
3. **`DocumentsRoot.pick()` et `.forget()` renvoient un `Either<Failure, T>` plutôt que de basculer silencieusement en `AsyncError`.** Les widgets appelants (carte, section Réglages, vue « accès perdu ») affichent eux-mêmes la `SnackBar` d'échec avec `failureMessage()`, en capturant `ScaffoldMessenger` et `S` avant l'`await` puisque `pick()`/`forget()` passent par `AsyncLoading` et peuvent démonter le widget appelant.
4. **Le mapping `PlatformException → DocumentsFailure` vit dans `NativeDocumentsRepository` (méthode privée `_call`), pas dans `guard()` de `core/result`.** Objectif : ne pas coupler le code générique de `core` aux codes du canal `colette/documents`. `DocumentsFailure` a en plus l'égalité par valeur, nécessaire pour comparer des `Either` dans les tests.
5. **`documentsErrorIo` est une clé l10n à part**, distincte de `documentsErrorWrite` et `documentsErrorNotDownloaded` déjà prévues. `failureMessage()` mappe `io` sur `documentsErrorIo` (message générique), tandis que la page Documents et la tuile de fichier affichent directement leur propre message plus précis pour une écriture ou un aperçu en échec.
6. **La section Réglages sans dossier a été changée de disposition.** Le bouton « Choisir le dossier partagé » prévu en `trailing` d'un `ListTile` débordait à la largeur d'un iPhone standard (375 pt) ; il est passé sous le `ListTile`, dans une `Column`.
7. **Opérations concurrentes explicitement refusées côté Swift.** Un verrou global unique dans `DocumentsPlugin` couvre les quatre opérations système et l'attente de téléchargement d'un aperçu : toute deuxième opération, même d'un autre type, échoue avec `cancelled` (ignoré par l'UI) au lieu de se comporter de façon indéfinie — sans lui, un scan pouvait présenter la caméra pendant qu'un aperçu attendait encore son téléchargement, puis Quick Look s'ouvrait par-dessus. Ce n'était pas détaillé dans la version initiale de la spec.
8. **Les sources Swift sont enregistrées dans `Runner.xcodeproj` par un script Ruby idempotent** (`ios/scripts/add_documents_sources.rb`, gem `xcodeproj`) plutôt qu'à la main dans Xcode, pour que l'ajout de fichiers reste reproductible et scriptable.
