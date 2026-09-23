import Flutter
import Foundation
import os.log

/// Observe un dossier pour un abonnement Flutter : première liste immédiate,
/// puis relistage à chaque mise à jour iCloud (`NSMetadataQuery`) ou sur demande.
/// Tout s'exécute sur le thread principal sauf le listage lui-même.
///
/// Contrat avec Flutter : au moins un événement (liste, ou erreur puis fin) est
/// toujours envoyé après `start(sink:)`, sinon un désabonnement qui a couru en
/// parallèle de `openFolderStream` ne libérerait jamais le canal.
final class DocumentsFolderWatcher {
  let relativePath: String

  private let root: ScopedRoot
  private let folder: URL
  /// Dossier aux liens symboliques résolus : référence des comparaisons de chemins,
  /// la requête pouvant remonter `/var/…` là où le bookmark donne `/private/var/…`.
  private let canonicalFolder: URL
  private let query = NSMetadataQuery()
  private var observers: [NSObjectProtocol] = []
  private var sink: FlutterEventSink?
  /// Clé `DocumentsLister.progressKey` du fichier réel → dernière progression connue
  /// (0 à 1). Collante : voir `queryChanged()` et `forgetDownloaded(_:)`.
  private var progress: [String: Double] = [:]
  private var relisting = false
  private var relistPending = false
  private var stopped = false

  init(root: ScopedRoot, folder: URL, relativePath: String) {
    self.root = root
    self.folder = folder
    self.relativePath = relativePath
    canonicalFolder = DocumentsLister.canonical(folder)
  }

  deinit { stop() }

  /// Envoie la première liste puis démarre la requête de métadonnées.
  /// Sans effet après `stop()`.
  func start(sink: @escaping FlutterEventSink) {
    guard !stopped else { return }
    self.sink = sink
    relist()
    query.searchScopes = [NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    query.predicate = NSCompoundPredicate(
      orPredicateWithSubpredicates: folderPrefixes().map {
        NSPredicate(format: "%K BEGINSWITH %@", NSMetadataItemPathKey, $0)
      })
    // Regroupe les notifications pour éviter une rafale de relistages pendant un téléchargement.
    query.notificationBatchingInterval = 0.5
    let center = NotificationCenter.default
    for name in [Notification.Name.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate] {
      observers.append(
        center.addObserver(forName: name, object: query, queue: .main) { [weak self] note in
          self?.queryChanged(gathered: note.name == .NSMetadataQueryDidFinishGathering)
        })
    }
    if !query.start() {
      os_log(
        "DocumentsFolderWatcher : la requête iCloud n'a pas démarré pour %{public}@",
        type: .error, folder.path)
    }
  }

  /// Arrête la requête, referme la portée sécurisée ; plus aucun événement envoyé.
  /// Sans effet si déjà arrêté.
  func stop() {
    stopped = true
    let center = NotificationCenter.default
    observers.forEach { center.removeObserver($0) }
    observers.removeAll()
    query.stop()
    sink = nil
    root.close()
  }

  /// Relistage forcé, après une écriture ou une suppression.
  func refresh() { relist() }

  /// Préfixes du dossier sous ses deux formes possibles (`/private/var/…` et `/var/…`),
  /// pour que le prédicat ne dépende pas de la forme retenue par la requête.
  private func folderPrefixes() -> [String] {
    var prefixes: Set<String> = []
    for path in [folder.path, canonicalFolder.path] {
      prefixes.insert(path)
      if path.hasPrefix("/private/") {
        prefixes.insert(String(path.dropFirst("/private".count)))
      } else if path.hasPrefix("/var/") {
        prefixes.insert("/private" + path)
      }
    }
    return prefixes.map { $0.hasSuffix("/") ? $0 : $0 + "/" }
  }

  /// Recalcule la progression depuis la requête, puis reliste.
  ///
  /// Progression collante : un fichier déjà suivi garde sa dernière progression connue
  /// même quand la requête ne la donne plus (fin de téléchargement, avant le remplacement
  /// du placeholder sur le disque), pour que Flutter ne voie jamais `notDownloaded` après
  /// `downloading`. Il n'est oublié que si la requête ne le remonte plus, s'il porte une
  /// erreur de téléchargement, s'il est `current`, ou quand le listage le dit téléchargé
  /// (`forgetDownloaded(_:)`). Un fichier pas encore suivi n'entre qu'avec
  /// `IsDownloading` vrai et un pourcentage, pour qu'un placeholder jamais demandé
  /// ne paraisse pas en téléchargement.
  private func queryChanged(gathered: Bool) {
    query.disableUpdates()
    if gathered {
      os_log(
        "DocumentsFolderWatcher : %ld résultat(s) iCloud pour %{public}@",
        type: .info, query.resultCount, folder.path)
    }
    var next: [String: Double] = [:]
    for case let item as NSMetadataItem in query.results {
      guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
        item.value(forAttribute: NSMetadataUbiquitousItemDownloadingErrorKey) == nil,
        item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
          != NSMetadataUbiquitousItemDownloadingStatusCurrent
      else { continue }
      let real = DocumentsLister.realURL(for: URL(fileURLWithPath: path))
      let parent = DocumentsLister.canonical(real.deletingLastPathComponent())
      guard parent.path == canonicalFolder.path else { continue }
      let key = DocumentsLister.progressKey(
        canonicalFolder: canonicalFolder, name: real.lastPathComponent)
      let percent = (item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey)
        as? Double).map { min(max($0 / 100, 0), 1) }
      let isDownloading =
        item.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) as? Bool == true
      if let known = progress[key] {
        next[key] = percent ?? known
      } else if isDownloading, let percent {
        next[key] = percent
      }
    }
    query.enableUpdates()
    progress = next
    relist()
  }

  /// Oublie la progression des fichiers que le listage donne pour téléchargés.
  private func forgetDownloaded(_ entries: [[String: Any]]) {
    guard !progress.isEmpty else { return }
    for entry in entries where entry["downloadStatus"] as? String == "downloaded" {
      guard let name = entry["name"] as? String else { continue }
      progress.removeValue(
        forKey: DocumentsLister.progressKey(canonicalFolder: canonicalFolder, name: name))
    }
  }

  /// Un seul listage à la fois ; une demande arrivée pendant un listage en déclenche un autre après.
  private func relist() {
    guard sink != nil else { return }
    guard !relisting else {
      relistPending = true
      return
    }
    relisting = true
    let folder = self.folder
    let path = relativePath
    let progress = self.progress
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      let outcome = Result {
        try DocumentsLister.list(folder: folder, relativePath: path, progress: progress)
      }
      DispatchQueue.main.async {
        guard let self else { return }
        self.relisting = false
        guard let sink = self.sink else { return }
        switch outcome {
        case .success(let entries):
          self.forgetDownloaded(entries)
          sink(entries)
        case .failure(let error):
          let documentsError = error as? DocumentsError ?? .io(error.localizedDescription)
          sink(documentsError.flutterError)
          sink(FlutterEndOfEventStream)
          self.sink = nil
        }
        if self.relistPending {
          self.relistPending = false
          self.relist()
        }
      }
    }
  }
}
