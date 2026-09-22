import Foundation
import UIKit

/// Écriture coordonnée dans le dossier iCloud : PDF de scan, copie d'import, collisions.
enum DocumentsWriter {
  /// `nom.ext`, puis `nom (2).ext`, `nom (3).ext`… selon le contenu du dossier.
  static func uniqueURL(for name: String, in folder: URL) -> URL {
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

  /// Écrit les pages scannées dans un PDF ; renvoie le nom retenu après collision.
  static func writePDF(pages: [UIImage], named name: String, in folder: URL) throws -> String {
    let target = uniqueURL(for: name, in: folder)
    let data = UIGraphicsPDFRenderer(bounds: .zero).pdfData { context in
      for page in pages {
        let bounds = CGRect(origin: .zero, size: page.size)
        context.beginPage(withBounds: bounds, pageInfo: [:])
        page.draw(in: bounds)
      }
    }
    try coordinatedWrite(to: target) { url in try data.write(to: url, options: .atomic) }
    return target.lastPathComponent
  }

  /// Copie un fichier importé dans le dossier ; renvoie le nom retenu après collision.
  static func copy(_ source: URL, named name: String, in folder: URL) throws -> String {
    let target = uniqueURL(for: name, in: folder)
    try coordinatedWrite(to: target) { url in
      try FileManager.default.copyItem(at: source, to: url)
    }
    return target.lastPathComponent
  }

  private static func coordinatedWrite(to target: URL, _ body: (URL) throws -> Void) throws {
    var coordinationError: NSError?
    var writeError: Error?
    NSFileCoordinator().coordinate(
      writingItemAt: target, options: [], error: &coordinationError
    ) { url in
      do { try body(url) } catch { writeError = error }
    }
    let failure: Error? = writeError ?? coordinationError
    if let failure {
      throw DocumentsError.io(failure.localizedDescription)
    }
  }
}
