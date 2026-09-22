import Foundation

/// Racine résolue, avec la portée sécurisée ouverte jusqu'à `close()` ou la destruction.
final class ScopedRoot {
  let url: URL
  private var open = true

  init(url: URL) { self.url = url }

  func close() {
    guard open else { return }
    url.stopAccessingSecurityScopedResource()
    open = false
  }

  deinit { close() }
}

/// Bookmark de sécurité du dossier racine dans `UserDefaults`.
final class DocumentsStore {
  static let bookmarkKey = "colette.documents.rootBookmark"

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) { self.defaults = defaults }

  var hasRoot: Bool { defaults.data(forKey: Self.bookmarkKey) != nil }

  /// Enregistre l'URL renvoyée par le sélecteur ; renvoie le nom du dossier.
  func save(rootURL: URL) throws -> String {
    let accessed = rootURL.startAccessingSecurityScopedResource()
    defer { if accessed { rootURL.stopAccessingSecurityScopedResource() } }
    do {
      let data = try rootURL.bookmarkData()
      defaults.set(data, forKey: Self.bookmarkKey)
    } catch {
      throw DocumentsError.io(error.localizedDescription)
    }
    return rootURL.lastPathComponent
  }

  func forget() { defaults.removeObject(forKey: Self.bookmarkKey) }

  /// Résout le bookmark à chaque appel ; régénère un bookmark périmé.
  func openRoot() throws -> ScopedRoot {
    guard let data = defaults.data(forKey: Self.bookmarkKey) else {
      throw DocumentsError.noFolder
    }
    var stale = false
    let url: URL
    do {
      url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
    } catch {
      throw DocumentsError.noFolder
    }
    guard url.startAccessingSecurityScopedResource() else {
      throw DocumentsError.accessDenied
    }
    let root = ScopedRoot(url: url)
    if stale, let fresh = try? url.bookmarkData() {
      defaults.set(fresh, forKey: Self.bookmarkKey)
    }
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      root.close()
      throw DocumentsError.accessDenied
    }
    return root
  }

  /// Chemin relatif → URL sous la racine. Refuse `..`, `.` et un `/` initial.
  static func resolve(_ relativePath: String, under root: URL) throws -> URL {
    if relativePath.isEmpty { return root }
    if relativePath.hasPrefix("/") { throw DocumentsError.accessDenied }
    let parts = relativePath.split(separator: "/").map(String.init)
    if parts.contains("..") || parts.contains(".") { throw DocumentsError.accessDenied }
    return parts.reduce(root) { $0.appendingPathComponent($1) }
  }
}
