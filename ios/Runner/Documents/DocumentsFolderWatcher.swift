import Flutter
import Foundation

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
  /// Clé `DocumentsLister.progressKey` du fichier réel → progression (0 à 1), d'après la requête.
  private var progress: [String: Double] = [:]
  private var relisting = false
  private var relistPending = false

  init(root: ScopedRoot, folder: URL, relativePath: String) {
    self.root = root
    self.folder = folder
    self.relativePath = relativePath
    canonicalFolder = DocumentsLister.canonical(folder)
  }

  /// Envoie la première liste puis démarre la requête de métadonnées.
  func start(sink: @escaping FlutterEventSink) {
    self.sink = sink
    relist()
    query.searchScopes = [NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    query.predicate = NSCompoundPredicate(
      orPredicateWithSubpredicates: folderPrefixes().map {
        NSPredicate(format: "%K BEGINSWITH %@", NSMetadataItemPathKey, $0)
      })
    let center = NotificationCenter.default
    for name in [Notification.Name.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate] {
      observers.append(
        center.addObserver(forName: name, object: query, queue: .main) { [weak self] _ in
          self?.queryChanged()
        })
    }
    query.start()
  }

  /// Arrête la requête, referme la portée sécurisée ; plus aucun événement envoyé.
  /// Sans effet si déjà arrêté.
  func stop() {
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

  private func queryChanged() {
    query.disableUpdates()
    var next: [String: Double] = [:]
    for case let item as NSMetadataItem in query.results {
      guard item.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) as? Bool == true,
        let percent = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey)
          as? Double,
        let path = item.value(forAttribute: NSMetadataItemPathKey) as? String
      else { continue }
      let real = DocumentsLister.realURL(for: URL(fileURLWithPath: path))
      let parent = DocumentsLister.canonical(real.deletingLastPathComponent())
      guard parent.path == canonicalFolder.path else { continue }
      let key = DocumentsLister.progressKey(
        canonicalFolder: canonicalFolder, name: real.lastPathComponent)
      next[key] = min(max(percent / 100, 0), 1)
    }
    query.enableUpdates()
    progress = next
    relist()
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
