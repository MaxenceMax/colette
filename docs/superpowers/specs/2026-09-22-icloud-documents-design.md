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
| Résolution | Le bookmark est résolu à chaque appel, jamais mis en cache. S'il est périmé (`isStale`), il est régénéré et réécrit. S'il ne se résout pas, `noFolder`. |
| Listage | Sous-dossiers d'abord, triés par nom (insensible à la casse, `compareTo` sur la version minuscule). Puis fichiers par date de modification décroissante, nom croissant à égalité. Les fichiers cachés (nom commençant par `.`) sont exclus, sauf les placeholders iCloud, normalisés (voir Données). |
| Aperçu | `QLPreviewController` natif. Si le fichier n'est pas téléchargé, Swift lance `startDownloadingUbiquitousItem` et attend le statut `current`, avec un délai maximal de 30 secondes. Au-delà : `io`. |
| Scan | `VNDocumentCameraViewController`. Les pages sont rendues dans un PDF unique, nommé `Scan {jj}-{MM}-{aaaa} {HH}h{mm}.pdf` avec l'horloge de l'app (`clockProvider`), écrit dans le dossier courant. |
| Import | `UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)`. Le fichier est copié dans le dossier courant sous son nom d'origine. |
| Collision de nom | Résolue en Swift juste avant l'écriture : `nom (2).ext`, `nom (3).ext`, etc. |
| Écriture | Toujours via `NSFileCoordinator.coordinate(writingItemAt:)` dans la portée de `startAccessingSecurityScopedResource`. |
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

`core/ui/failure_message.dart` traduit `noFolder` et `accessDenied` par `documentsErrorAccess`, et `io` par `documentsErrorWrite`. `cancelled` n'a pas de message : l'UI l'ignore.

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

Côté Swift : `ios/Runner/Documents/DocumentsPlugin.swift` (enregistrement du canal, dispatch), `DocumentsStore.swift` (bookmark, résolution, portée sécurisée), `DocumentsLister.swift` (listage, normalisation des placeholders), `DocumentsWriter.swift` (PDF depuis les images du scan, copie, collision), `DocumentsPresenter.swift` (sélecteurs, `QLPreviewController`, `VNDocumentCameraViewController`, présentés depuis le `rootViewController`). Enregistré dans `AppDelegate.didInitializeImplicitFlutterEngine`.

`Info.plist` : ajout de `NSCameraUsageDescription` (« Colette utilise l'appareil photo pour scanner vos documents. »). Aucun entitlement iCloud nécessaire : le sélecteur de dossier suffit.

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
                                              documentsFolderProvider(path) (autoDispose, Future)
    providers/documents_root.dart             DocumentsRoot : FutureOr<DocumentRoot?>, pick(), forget()
    providers/documents_controller.dart       DocumentsController : preview, scan, importFile
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

`NativeDocumentsRepository` reçoit le `MethodChannel` en constructeur (injectable en test). Il enveloppe chaque appel dans `guard()` et convertit en amont les `PlatformException` en `DocumentsFailure` selon leur `code`.

### Providers

- `documentsRepositoryProvider` : `keepAlive`, construit `NativeDocumentsRepository(const MethodChannel('colette/documents'))`.
- `DocumentsRoot` (`keepAlive`) : `build()` appelle `rootFolder()`. `pick()` passe en `AsyncLoading`, appelle `pickRootFolder()`, puis `AsyncData(root)` ; sur `cancelled`, restaure l'état précédent sans erreur. `forget()` appelle `forgetRootFolder()` puis `AsyncData(null)` et invalide tous les `documentsFolderProvider`.
- `documentsFolderProvider(String path)` : `autoDispose`, appelle `list(path)` puis `sortDocumentEntries`. Un `Left` est relancé en exception pour que l'UI le reçoive en `AsyncError`.
- `DocumentsController` (`autoDispose`, `FutureOr<void> build() {}`) : `preview(path)`, `scan(folderPath)` (nom calculé avec `clockProvider` et `buildScanFileName`), `importFile(folderPath)`. Après un `scan` ou un `importFile` réussi, `ref.invalidate(documentsFolderProvider(folderPath))`. `cancelled` remet `AsyncData(null)` sans erreur. Toute autre failure passe en `AsyncError`. Les pages `ref.watch`ent ce contrôleur dans `build` et `ref.listen`ent ses erreurs pour la `SnackBar`.

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

- `AsyncData` vide : `EmptyState` avec `documentsEmptyFolder`.
- `AsyncData` : `ListView.builder` de `DocumentEntryTile`, dans un `RefreshIndicator` qui invalide le provider.
- `AsyncLoading` : indicateur centré.
- `AsyncError(error: DocumentsFailure(reason: noFolder || accessDenied))` : `DocumentsLostAccessView` avec `documentsLostAccessBody` et bouton `documentsCardPick` qui appelle `pick()` puis, en cas de succès, `context.go(AppRoutes.todayDocuments)` pour repartir de la racine.
- Autre `AsyncError` : `EmptyState` avec le message générique de `failureMessage`.

`DocumentEntryTile` : icône `folder` pour un dossier, `picture_as_pdf` pour `.pdf`, `image` pour `.jpg`, `.jpeg`, `.png`, `.heic`, `insert_drive_file` sinon. Titre : `name`. Sous-titre : date de modification formatée `d MMM yyyy`, absente pour un dossier. Trailing : chevron pour un dossier, icône `cloud_download_outlined` si `notDownloaded`, indicateur circulaire si `downloading` ou si l'aperçu de cette ligne est en cours, rien sinon. Tap dossier : `push` vers le sous-dossier. Tap fichier : `controller.preview(entry.path)`.

Bouton flottant `+` : `showModalBottomSheet` avec deux `ListTile` : `documentsActionScan` (icône `document_scanner`) et `documentsActionImport` (icône `upload_file`). Chacun ferme la feuille puis appelle le contrôleur avec le `path` courant. Pendant l'action, le bouton est désactivé.

Erreurs via `ref.listen` sur le contrôleur : `io` → `SnackBar` `documentsErrorNotDownloaded` si l'action était un aperçu, `documentsErrorWrite` sinon ; `noFolder` et `accessDenied` → invalide `documentsFolderProvider(path)` pour afficher la vue « accès perdu ».

### Réglages

`DocumentsRootSection` dans `HouseholdSection`, après le code du foyer. `switch` sur `documentsRootProvider` : sans dossier, `ListTile` `settingsDocumentsNone` avec bouton `documentsCardPick` ; avec dossier, `ListTile` titre `settingsDocumentsFolder`, sous-titre `root.name`, et deux `TextButton` : `settingsDocumentsChange` (appelle `pick()`) et `settingsDocumentsForget` (appelle `forget()` après un `AlertDialog` de confirmation `settingsDocumentsForgetConfirm`).

### Clés l10n (`app_fr.arb`)

`documentsCardTitle` « Documents », `documentsCardEmptyBody` « Retrouvez vos ordonnances et documents », `documentsCardPick` « Choisir le dossier partagé », `documentsEmptyFolder` « Aucun document dans ce dossier », `documentsLostAccessBody` « Colette n'a plus accès au dossier », `documentsActionScan` « Scanner un document », `documentsActionImport` « Importer un fichier », `documentsErrorNotDownloaded` « Ce document n'est pas encore téléchargé sur cet iPhone », `documentsErrorWrite` « Impossible d'enregistrer le document », `documentsErrorAccess` « Colette n'a pas accès à ce dossier », `settingsDocumentsNone` « Aucun dossier choisi », `settingsDocumentsFolder` « Dossier documents », `settingsDocumentsChange` « Changer de dossier », `settingsDocumentsForget` « Oublier le dossier », `settingsDocumentsForgetConfirm` « Colette n'affichera plus ce dossier. Vos fichiers ne sont pas supprimés. ».

Clair et sombre : couleurs uniquement via `AppColors`, aucune nouvelle couleur attendue.

## 8. Tests

- **Domaine** (purs) : `sortDocumentEntries` (dossiers avant fichiers, tri par nom insensible à la casse, fichiers par date décroissante puis nom) ; `buildScanFileName` avec une date fixe → `Scan 22-09-2026 14h32.pdf`.
- **Data** : `NativeDocumentsRepository` avec `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`. Un test par méthode (arguments transmis, résultat mappé), un test par code d'erreur (`noFolder`, `accessDenied`, `cancelled`, `io`, code inconnu → `UnknownFailure`), `DocumentEntryDto.fromMap` avec les trois statuts et un `modifiedAt` en ms.
- **Présentation** (`pumpApp` + `FakeDocumentsRepository` dans `test/helpers/`) : carte sans dossier puis avec dossier ; tap sur « Choisir » appelle `pickRootFolder` ; page avec liste triée ; tap sur un dossier pousse le sous-dossier ; état vide ; état accès perdu sur `accessDenied` ; tap fichier appelle `preview` ; menu « + » appelle `scan` avec le nom attendu via `FixedClock` puis invalide la liste ; `cancelled` n'affiche aucune `SnackBar` ; `io` affiche la bonne `SnackBar` ; section Réglages, oubli avec confirmation.
- **Swift** : pas de test automatisé. Liste de contrôle manuelle sur un iPhone réel avec le dossier partagé :
  1. Choisir le dossier, vérifier le nom sur la carte.
  2. Lister la racine et un sous-dossier, vérifier le tri.
  3. Ouvrir un fichier déjà téléchargé, puis un fichier avec l'icône nuage.
  4. Scanner deux pages, vérifier le PDF dans Fichiers sur les deux iPhones.
  5. Importer un PDF depuis Mail, puis le même une seconde fois : suffixe `(2)`.
  6. Tuer et relancer l'app : le dossier est toujours accessible.
  7. Renommer le dossier dans Fichiers : l'accès tient (bookmark), le nom affiché suit après « Changer de dossier ».
  8. Supprimer le dossier : vue « accès perdu », re-choix fonctionnel.
  9. Mode avion : listage OK, aperçu d'un fichier nuage → `SnackBar`.

## 9. Livraison

- **Lot 1, lecture** : failures, entités, repository, pont Swift (`pickRootFolder`, `rootFolder`, `forgetRootFolder`, `list`, `preview`), providers, carte, page, section Réglages, l10n, tests.
- **Lot 2, écriture** : `scan`, `importFile`, `buildScanFileName`, bouton `+`, `NSCameraUsageDescription`, tests associés.

Le lot 1 est livrable seul.
