import Foundation
import UIKit

/// Écriture coordonnée dans le dossier iCloud : PDF de scan, copie d'import, collisions.
enum DocumentsWriter {
  /// Page A4 portrait en points, base de la géométrie des PDF de scan.
  private static let a4 = CGSize(width: 595, height: 842)

  /// `nom.ext`, puis `nom (2).ext`, `nom (3).ext`… selon le contenu du dossier.
  /// Refuse un nom vide, `.`, `..` ou contenant `/`.
  static func uniqueURL(for name: String, in folder: URL) throws -> URL {
    guard !name.isEmpty, name != ".", name != "..", !name.contains("/") else {
      throw DocumentsError.accessDenied
    }
    let base = (name as NSString).deletingPathExtension
    let ext = (name as NSString).pathExtension
    var candidate = folder.appendingPathComponent(name)
    var index = 2
    while exists(candidate) {
      let next = ext.isEmpty ? "\(base) (\(index))" : "\(base) (\(index)).\(ext)"
      candidate = folder.appendingPathComponent(next)
      index += 1
    }
    return candidate
  }

  private static func exists(_ url: URL) -> Bool {
    let placeholder = url.deletingLastPathComponent()
      .appendingPathComponent(".\(url.lastPathComponent).icloud")
    return FileManager.default.fileExists(atPath: url.path)
      || FileManager.default.fileExists(atPath: placeholder.path)
  }

  /// Écrit les pages scannées dans un PDF A4 ; renvoie le nom retenu après collision.
  static func writePDF(pages: [UIImage], named name: String, in folder: URL) throws -> String {
    guard !pages.isEmpty else { throw DocumentsError.cancelled }
    let target = try uniqueURL(for: name, in: folder)
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: a4))
    try coordinatedWrite(to: target) { url in
      try renderer.writePDF(to: url) { context in
        for page in pages {
          let bounds = CGRect(origin: .zero, size: pageSize(for: page))
          context.beginPage(withBounds: bounds, pageInfo: [:])
          page.draw(in: fitted(page.size, in: bounds))
        }
      }
    }
    return target.lastPathComponent
  }

  /// A4 portrait, ou A4 paysage pour une image plus large que haute.
  private static func pageSize(for image: UIImage) -> CGSize {
    image.size.width > image.size.height
      ? CGSize(width: a4.height, height: a4.width) : a4
  }

  /// Rectangle centré dans la page, conservant le rapport d'aspect de l'image.
  private static func fitted(_ size: CGSize, in bounds: CGRect) -> CGRect {
    guard size.width > 0, size.height > 0 else { return bounds }
    let scale = min(bounds.width / size.width, bounds.height / size.height)
    let width = size.width * scale
    let height = size.height * scale
    return CGRect(
      x: bounds.midX - width / 2, y: bounds.midY - height / 2, width: width, height: height)
  }

  /// Copie un fichier importé dans le dossier ; renvoie le nom retenu après collision.
  static func copy(_ source: URL, named name: String, in folder: URL) throws -> String {
    let target = try uniqueURL(for: name, in: folder)
    try coordinatedWrite(to: target) { url in
      try FileManager.default.copyItem(at: source, to: url)
    }
    return target.lastPathComponent
  }

  /// Supprime un fichier sous coordination iCloud, sur son URL logique (fichier réel).
  /// `trashItem` est tenté d'abord pour que le fichier rejoigne « Récemment supprimés »
  /// quand iOS le permet, `removeItem` sert de repli. Si seul le placeholder
  /// `.nom.ext.icloud` existe, c'est lui qui est supprimé.
  static func delete(_ url: URL) throws {
    try coordinatedWrite(to: url, options: .forDeleting) { target in
      let manager = FileManager.default
      guard manager.fileExists(atPath: target.path) else {
        try manager.removeItem(
          at: target.deletingLastPathComponent()
            .appendingPathComponent(".\(target.lastPathComponent).icloud"))
        return
      }
      do {
        try manager.trashItem(at: target, resultingItemURL: nil)
      } catch {
        try manager.removeItem(at: target)
      }
    }
  }

  private static func coordinatedWrite(
    to target: URL, options: NSFileCoordinator.WritingOptions = [],
    _ body: (URL) throws -> Void
  ) throws {
    var coordinationError: NSError?
    var writeError: Error?
    NSFileCoordinator().coordinate(
      writingItemAt: target, options: options, error: &coordinationError
    ) { url in
      do { try body(url) } catch { writeError = error }
    }
    let failure: Error? = writeError ?? coordinationError
    if let failure {
      throw DocumentsError.io(failure.localizedDescription)
    }
  }
}
