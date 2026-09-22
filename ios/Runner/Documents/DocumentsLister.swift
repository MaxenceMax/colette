import Foundation

/// Listage d'un dossier et téléchargement iCloud à la demande.
enum DocumentsLister {
  private static let keys: Set<URLResourceKey> = [
    .isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isUbiquitousItemKey,
    .ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey,
  ]

  private static let placeholderSuffix = ".icloud"

  /// Entrées d'un dossier, au format attendu par `DocumentEntryDto`.
  static func list(folder: URL, relativePath: String) throws -> [[String: Any]] {
    let urls: [URL]
    do {
      urls = try FileManager.default.contentsOfDirectory(
        at: folder, includingPropertiesForKeys: Array(keys), options: [])
    } catch {
      throw DocumentsError.io(error.localizedDescription)
    }
    return urls.compactMap { url -> [String: Any]? in
      let raw = url.lastPathComponent
      let isPlaceholder = raw.hasPrefix(".") && raw.hasSuffix(placeholderSuffix)
      if raw.hasPrefix(".") && !isPlaceholder { return nil }
      let values = try? url.resourceValues(forKeys: keys)
      let isDirectory = values?.isDirectory ?? false
      let name = isPlaceholder ? normalizedName(raw) : raw
      let modified = values?.contentModificationDate ?? Date(timeIntervalSince1970: 0)
      return [
        "name": name,
        "path": relativePath.isEmpty ? name : "\(relativePath)/\(name)",
        "isDirectory": isDirectory,
        "size": isDirectory ? 0 : (values?.fileSize ?? 0),
        "modifiedAt": Int(modified.timeIntervalSince1970 * 1000),
        "downloadStatus": status(
          isDirectory: isDirectory, isPlaceholder: isPlaceholder, values: values),
      ]
    }
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

  private static func isAvailable(_ url: URL) -> Bool {
    guard FileManager.default.fileExists(atPath: url.path) else { return false }
    let values = try? url.resourceValues(forKeys: [
      .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey,
    ])
    guard values?.isUbiquitousItem == true else { return true }
    let status = values?.ubiquitousItemDownloadingStatus
    return status == .current || status == .downloaded
  }

  /// Lance le téléchargement si besoin et attend (30 s max) que le fichier soit lisible.
  static func ensureDownloaded(
    _ located: URL, timeout: TimeInterval = 30,
    completion: @escaping (Result<URL, DocumentsError>) -> Void
  ) {
    let real = realURL(for: located)
    if isAvailable(real) {
      completion(.success(real))
      return
    }
    do {
      try FileManager.default.startDownloadingUbiquitousItem(at: real)
    } catch {
      completion(.failure(.io(error.localizedDescription)))
      return
    }
    poll(real, deadline: Date().addingTimeInterval(timeout), completion: completion)
  }

  private static func poll(
    _ url: URL, deadline: Date, completion: @escaping (Result<URL, DocumentsError>) -> Void
  ) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
      if isAvailable(url) {
        DispatchQueue.main.async { completion(.success(url)) }
      } else if Date() > deadline {
        DispatchQueue.main.async { completion(.failure(.io("Téléchargement trop long"))) }
      } else {
        poll(url, deadline: deadline, completion: completion)
      }
    }
  }
}
