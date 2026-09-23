// Rend les SVG de assets/brand/ en PNG : icône de l'app, launch screen natif, asset de l'intro Flutter.
// Usage (depuis la racine du dépôt) : swift tool/brand/export.swift
import AppKit
import ImageIO
import UniformTypeIdentifiers

let brand = "assets/brand"
let xcassets = "ios/Runner/Assets.xcassets"

/// Couleurs de la palette « Cocon cannelle » (voir lib/core/theme/app_colors.dart).
enum Palette {
  static let powder = NSColor(srgbRed: 0xF3 / 255, green: 0xE2 / 255, blue: 0xDA / 255, alpha: 1)
  static let cocoa = NSColor(srgbRed: 0x1C / 255, green: 0x15 / 255, blue: 0x14 / 255, alpha: 1)
  static let inkLight = "#2E2320"
  static let inkDark = "#F1E6E0"
}

func loadSVG(_ name: String, recolor: [String: String] = [:]) -> NSImage {
  var source = try! String(contentsOfFile: "\(brand)/\(name)", encoding: .utf8)
  for (from, to) in recolor { source = source.replacingOccurrences(of: from, with: to) }
  guard let image = NSImage(data: Data(source.utf8)) else { fatalError("SVG illisible : \(name)") }
  return image
}

/// Dessine dans un canevas de [width] × [height] points à l'échelle [scale] et écrit un PNG.
/// [opaque] supprime le canal alpha (exigé pour l'icône principale).
func write(
  _ path: String, width: CGFloat, height: CGFloat, scale: CGFloat = 1, opaque: Bool = false,
  draw: () -> Void
) {
  let pixelsWide = Int(width * scale)
  let pixelsHigh = Int(height * scale)
  let alpha: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
  let context = CGContext(
    data: nil, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: alpha.rawValue)!
  context.scaleBy(x: scale, y: scale)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
  draw()
  NSGraphicsContext.restoreGraphicsState()
  let url = URL(fileURLWithPath: path)
  try! FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(destination, context.makeImage()!, nil)
  CGImageDestinationFinalize(destination)
  print("écrit \(path) (\(pixelsWide)×\(pixelsHigh))")
}

func writeJSON(_ path: String, _ json: String) {
  try! json.write(toFile: path, atomically: true, encoding: .utf8)
  print("écrit \(path)")
}

// MARK: - Icône

let logo = loadSVG("logo.svg")
let iconRect = NSRect(x: 0, y: 0, width: 1024, height: 1024)
let iconSet = "\(xcassets)/AppIcon.appiconset"

write("\(iconSet)/icon.png", width: 1024, height: 1024, opaque: true) {
  Palette.powder.setFill()
  iconRect.fill()
  logo.draw(in: iconRect)
}
write("\(iconSet)/icon-dark.png", width: 1024, height: 1024, opaque: true) {
  Palette.cocoa.setFill()
  iconRect.fill()
  logo.draw(in: iconRect)
}
write("\(iconSet)/icon-tinted.png", width: 1024, height: 1024) {
  loadSVG("logo-tinted.svg").draw(in: iconRect)
}
writeJSON(
  "\(iconSet)/Contents.json",
  """
  {
    "images" : [
      { "filename" : "icon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
      {
        "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
        "filename" : "icon-dark.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024"
      },
      {
        "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ],
        "filename" : "icon-tinted.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024"
      }
    ],
    "info" : { "author" : "xcode", "version" : 1 }
  }

  """)

// MARK: - Visuel de lancement (logo + wordmark)

/// Taille logique du visuel, identique pour le natif et l'intro Flutter.
let splashWidth: CGFloat = 200
let splashHeight: CGFloat = 240

func drawSplash(ink: String) {
  let wordmark = loadSVG("wordmark.svg", recolor: [Palette.inkLight: ink])
  // Le canevas du logo inclut ses marges d'icône : on le déborde pour garder le bébé grand.
  logo.draw(in: NSRect(x: -20, y: 26, width: 240, height: 240))
  let wordmarkWidth: CGFloat = 150
  let wordmarkHeight = wordmarkWidth * wordmark.size.height / wordmark.size.width
  wordmark.draw(
    in: NSRect(
      x: (splashWidth - wordmarkWidth) / 2, y: 6, width: wordmarkWidth, height: wordmarkHeight))
}

let launchSet = "\(xcassets)/LaunchImage.imageset"
for (suffix, ink) in [("", Palette.inkLight), ("Dark", Palette.inkDark)] {
  for scale in [1, 2, 3] {
    let density = scale == 1 ? "" : "@\(scale)x"
    write(
      "\(launchSet)/LaunchImage\(suffix)\(density).png", width: splashWidth, height: splashHeight,
      scale: CGFloat(scale)
    ) { drawSplash(ink: ink) }
  }
}
let flutterNames = [("splash", Palette.inkLight), ("splash_dark", Palette.inkDark)]
for (name, ink) in flutterNames {
  for scale in [1, 2, 3] {
    let folder = scale == 1 ? brand : "\(brand)/\(scale).0x"
    write("\(folder)/\(name).png", width: splashWidth, height: splashHeight, scale: CGFloat(scale)) {
      drawSplash(ink: ink)
    }
  }
}

func launchEntry(_ file: String, _ scale: Int, dark: Bool) -> String {
  let appearance =
    dark ? "\"appearances\" : [ { \"appearance\" : \"luminosity\", \"value\" : \"dark\" } ], " : ""
  return "    { \(appearance)\"filename\" : \"\(file)\", \"idiom\" : \"universal\", \"scale\" : \"\(scale)x\" }"
}
var launchEntries: [String] = []
for scale in [1, 2, 3] {
  let density = scale == 1 ? "" : "@\(scale)x"
  launchEntries.append(launchEntry("LaunchImage\(density).png", scale, dark: false))
  launchEntries.append(launchEntry("LaunchImageDark\(density).png", scale, dark: true))
}
writeJSON(
  "\(launchSet)/Contents.json",
  """
  {
    "images" : [
  \(launchEntries.joined(separator: ",\n"))
    ],
    "info" : { "author" : "xcode", "version" : 1 }
  }

  """)
