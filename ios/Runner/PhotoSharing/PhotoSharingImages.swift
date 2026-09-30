import ImageIO
import UIKit

/// Photos préparées pour Messages : JPEG réduits dans `tmp/photo-sharing/`.
enum PhotoSharingImages {
  private static let maxDimension: CGFloat = 2048
  private static let quality: CGFloat = 0.8

  static var directory: URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("photo-sharing", isDirectory: true)
  }

  /// Photo de l'appareil : réduit l'image (grand côté ≤ 2048 px), l'écrit en JPEG et renvoie son chemin.
  static func write(_ image: UIImage) throws -> String {
    guard let data = resized(image).jpegData(compressionQuality: quality) else {
      throw PhotoSharingError.io("Encodage JPEG impossible")
    }
    return try store(data)
  }

  /// Écrit le JPEG dans le dossier des photos et renvoie son chemin.
  private static func store(_ data: Data) throws -> String {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
    try data.write(to: url, options: .atomic)
    return url.path
  }

  /// Réduit à la lecture le fichier image donné (ImageIO, sans décoder la pleine
  /// résolution), orientation EXIF appliquée, l'écrit en JPEG et renvoie son chemin.
  /// Sûr hors du thread principal.
  static func write(fileAt source: URL) throws -> String {
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, sourceOptions) else {
      throw PhotoSharingError.io("Photo illisible")
    }
    let thumbnailOptions =
      [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimension,
        kCGImageSourceShouldCacheImmediately: true,
      ] as CFDictionary
    guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions),
      let data = UIImage(cgImage: image).jpegData(compressionQuality: quality)
    else {
      throw PhotoSharingError.io("Encodage JPEG impossible")
    }
    return try store(data)
  }

  /// Supprime les fichiers donnés, uniquement s'ils sont dans le dossier des photos.
  static func discard(_ paths: [String]) {
    for path in paths where path.hasPrefix(directory.path) {
      try? FileManager.default.removeItem(atPath: path)
    }
  }

  /// Vide le dossier (au lancement : restes d'un envoi interrompu).
  static func discardAll() {
    try? FileManager.default.removeItem(at: directory)
  }

  /// Dessin à l'échelle 1 : l'orientation EXIF est appliquée par `draw(in:)`.
  private static func resized(_ image: UIImage) -> UIImage {
    let pixels = CGSize(
      width: image.size.width * image.scale, height: image.size.height * image.scale)
    let ratio = min(1, maxDimension / max(pixels.width, pixels.height))
    let target = CGSize(
      width: (pixels.width * ratio).rounded(), height: (pixels.height * ratio).rounded())
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    return UIGraphicsImageRenderer(size: target, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: target))
    }
  }
}
