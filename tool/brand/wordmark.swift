// Génère le wordmark « Colette » en tracés SVG depuis un TTF Fraunces 600.
// Usage : swift tool/brand/wordmark.swift <Fraunces-600.ttf> > assets/brand/wordmark.svg
import CoreText
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
  FileHandle.standardError.write(Data("usage : wordmark.swift <Fraunces-600.ttf>\n".utf8))
  exit(1)
}
guard
  let descriptors = CTFontManagerCreateFontDescriptorsFromURL(
    URL(fileURLWithPath: arguments[1]) as CFURL) as? [CTFontDescriptor],
  let descriptor = descriptors.first
else {
  FileHandle.standardError.write(Data("police illisible : \(arguments[1])\n".utf8))
  exit(1)
}

let font = CTFontCreateWithFontDescriptor(descriptor, 200, nil)
let text = NSAttributedString(
  string: "Colette", attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
let line = CTLineCreateWithAttributedString(text)
let glyphsPath = CGMutablePath()
for run in CTLineGetGlyphRuns(line) as! [CTRun] {
  let count = CTRunGetGlyphCount(run)
  var glyphs = [CGGlyph](repeating: 0, count: count)
  var positions = [CGPoint](repeating: .zero, count: count)
  CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
  CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
  for index in 0..<count {
    if let glyph = CTFontCreatePathForGlyph(font, glyphs[index], nil) {
      glyphsPath.addPath(
        glyph,
        transform: CGAffineTransform(translationX: positions[index].x, y: positions[index].y))
    }
  }
}

let bounds = glyphsPath.boundingBoxOfPath
var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: -bounds.minX, ty: bounds.maxY)
let svgPath = glyphsPath.copy(using: &flip)!

func number(_ value: CGFloat) -> String { String(format: "%.1f", Double(value)) }
var data = ""
svgPath.applyWithBlock { element in
  let points = element.pointee.points
  switch element.pointee.type {
  case .moveToPoint: data += "M\(number(points[0].x)) \(number(points[0].y))"
  case .addLineToPoint: data += "L\(number(points[0].x)) \(number(points[0].y))"
  case .addQuadCurveToPoint:
    data += "Q\(number(points[0].x)) \(number(points[0].y)) \(number(points[1].x)) \(number(points[1].y))"
  case .addCurveToPoint:
    data +=
      "C\(number(points[0].x)) \(number(points[0].y)) \(number(points[1].x)) \(number(points[1].y)) \(number(points[2].x)) \(number(points[2].y))"
  case .closeSubpath: data += "Z"
  @unknown default: break
  }
}

let width = number(bounds.width)
let height = number(bounds.height)
print(
  """
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(width) \(height)" width="\(width)" height="\(height)">
    <path d="\(data)" fill="#2E2320"/>
  </svg>
  """)
