import Foundation

/// Listage d'un dossier et état de téléchargement iCloud.
enum DocumentsLister {
  private static let keys: Set<URLResourceKey> = [
    .isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isUbiquitousItemKey,
    .ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey,
  ]

  private static let placeholderSuffix = ".icloud"

  private typealias Entry = (path: String, isPlaceholder: Bool, values: [String: Any])

  /// Entrées d'un dossier, au format attendu par `DocumentEntryDto`.
  /// `progress` : clé `progressKey(canonicalFolder:name:)` du fichier réel → progression
  /// (0 à 1) fournie par la requête de métadonnées ; un fichier qui y figure est `downloading`.
  static func list(
    folder: URL, relativePath: String, progress: [String: Double] = [:]
  ) throws -> [[String: Any]] {
    let urls: [URL]
    do {
      urls = try FileManager.default.contentsOfDirectory(
        at: folder, includingPropertiesForKeys: Array(keys), options: [])
    } catch {
      throw DocumentsError.io(error.localizedDescription)
    }
    let canonicalFolder = progress.isEmpty ? nil : canonical(folder)
    let entries = urls.compactMap { url -> Entry? in
      let raw = url.lastPathComponent
      let isPlaceholder = raw.hasPrefix(".") && raw.hasSuffix(placeholderSuffix)
      if raw.hasPrefix(".") && !isPlaceholder { return nil }
      let values = try? url.resourceValues(forKeys: keys)
      let isDirectory = values?.isDirectory ?? false
      let name = isPlaceholder ? normalizedName(raw) : raw
      let path = relativePath.isEmpty ? name : "\(relativePath)/\(name)"
      let modified = values?.contentModificationDate ?? Date(timeIntervalSince1970: 0)
      var status = self.status(
        isDirectory: isDirectory, isPlaceholder: isPlaceholder, values: values)
      var entry: [String: Any] = [
        "name": name,
        "path": path,
        "isDirectory": isDirectory,
        "size": isDirectory ? 0 : (values?.fileSize ?? 0),
        "modifiedAt": Int(modified.timeIntervalSince1970 * 1000),
      ]
      if status != "downloaded", let canonicalFolder,
        let percent = progress[progressKey(canonicalFolder: canonicalFolder, name: name)]
      {
        status = "downloading"
        entry["downloadProgress"] = percent
      }
      entry["downloadStatus"] = status
      return (path, isPlaceholder, entry)
    }
    return deduplicated(entries)
  }

  /// Dossier existant, liens symboliques résolus (`/private/var` et `/var` donnent le même
  /// chemin) : base commune des clés de progression côté listage et côté requête.
  static func canonical(_ folder: URL) -> URL {
    folder.resolvingSymlinksInPath()
  }

  /// Clé de progression du fichier réel `name` dans un dossier déjà canonique.
  /// Seul le dossier est canonisé : le fichier réel d'un placeholder n'existe pas encore,
  /// et `resolvingSymlinksInPath` ne retire `/private` que d'un chemin existant.
  static func progressKey(canonicalFolder: URL, name: String) -> String {
    canonicalFolder.appendingPathComponent(name).path
  }

  /// Une seule entrée par chemin : le fichier réel prime sur son placeholder `.x.ext.icloud`.
  private static func deduplicated(_ entries: [Entry]) -> [[String: Any]] {
    var indexByPath: [String: Int] = [:]
    var kept: [Entry] = []
    for entry in entries {
      guard let index = indexByPath[entry.path] else {
        indexByPath[entry.path] = kept.count
        kept.append(entry)
        continue
      }
      if kept[index].isPlaceholder && !entry.isPlaceholder { kept[index] = entry }
    }
    return kept.map(\.values)
  }

  private static func status(isDirectory: Bool, isPlaceholder: Bool, values: URLResourceValues?)
    -> String
  {
    if isDirectory { return "downloaded" }
    if isPlaceholder { return "notDownloaded" }
    guard values?.isUbiquitousItem == true else { return "downloaded" }
    let downloadStatus = values?.ubiquitousItemDownloadingStatus
    if downloadStatus == .current || downloadStatus == .downloaded { return "downloaded" }
    if values?.ubiquitousItemIsDownloading == true { return "downloading" }
    return "notDownloaded"
  }

  /// `.nom.ext.icloud` → `nom.ext`.
  private static func normalizedName(_ raw: String) -> String {
    String(raw.dropFirst().dropLast(placeholderSuffix.count))
  }

  /// URL réelle du fichier (sans préfixe `.` ni suffixe `.icloud`).
  static func realURL(for url: URL) -> URL {
    let raw = url.lastPathComponent
    guard raw.hasPrefix("."), raw.hasSuffix(placeholderSuffix) else { return url }
    return url.deletingLastPathComponent().appendingPathComponent(normalizedName(raw))
  }

  /// Fichier réel ou placeholder iCloud pour un chemin relatif.
  static func locate(_ relativePath: String, under root: URL) throws -> URL {
    let url = try DocumentsStore.resolve(relativePath, under: root)
    if FileManager.default.fileExists(atPath: url.path) { return url }
    let placeholder = url.deletingLastPathComponent()
      .appendingPathComponent(".\(url.lastPathComponent)\(placeholderSuffix)")
    if FileManager.default.fileExists(atPath: placeholder.path) { return placeholder }
    throw DocumentsError.io("Fichier introuvable")
  }

  /// Vrai si le fichier réel existe et est lisible localement (téléchargé, ou hors iCloud).
  static func isAvailable(_ url: URL) -> Bool {
    guard FileManager.default.fileExists(atPath: url.path) else { return false }
    let values = try? url.resourceValues(forKeys: [
      .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey,
    ])
    guard values?.isUbiquitousItem == true else { return true }
    let status = values?.ubiquitousItemDownloadingStatus
    return status == .current || status == .downloaded
  }

  /// Lance le téléchargement iCloud du fichier réel s'il n'est pas déjà lisible.
  static func startDownload(_ located: URL) throws {
    let real = realURL(for: located)
    if isAvailable(real) { return }
    do {
      try FileManager.default.startDownloadingUbiquitousItem(at: real)
    } catch {
      throw DocumentsError.io(error.localizedDescription)
    }
  }
}
