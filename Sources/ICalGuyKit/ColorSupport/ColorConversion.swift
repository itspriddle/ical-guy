import Foundation

struct ColorConversion {
  struct RGB: Equatable {
    let r: UInt8
    let g: UInt8
    let b: UInt8
  }

  static func hexToRGB(_ hex: String) -> RGB? {
    var h = hex.trimmingCharacters(in: .whitespaces)
    if h.hasPrefix("#") { h = String(h.dropFirst()) }
    guard h.count == 6, let value = UInt32(h, radix: 16) else { return nil }
    return RGB(
      r: UInt8((value >> 16) & 0xFF),
      g: UInt8((value >> 8) & 0xFF),
      b: UInt8(value & 0xFF)
    )
  }

  /// Map RGB to nearest ANSI 256-color index (16-231 color cube + 232-255 grayscale).
  static func rgbToANSI256(_ rgb: RGB) -> UInt8 {
    // Check if close to grayscale first
    let r = Int(rgb.r)
    let g = Int(rgb.g)
    let b = Int(rgb.b)
    if r == g && g == b {
      if r < 8 { return 16 }
      if r > 248 { return 231 }
      return UInt8(232 + Int(round(Double(r - 8) / 247.0 * 23.0)))
    }

    // Map to 6x6x6 color cube (indices 16-231)
    let ri = Int(round(Double(r) / 255.0 * 5.0))
    let gi = Int(round(Double(g) / 255.0 * 5.0))
    let bi = Int(round(Double(b) / 255.0 * 5.0))
    return UInt8(16 + 36 * ri + 6 * gi + bi)
  }

  /// Map RGB to nearest basic ANSI 16 color index.
  static func rgbToANSI16(_ rgb: RGB) -> UInt8 {
    let ansi16Colors: [(UInt8, RGB)] = [
      (30, RGB(r: 0, g: 0, b: 0)),  // black
      (31, RGB(r: 170, g: 0, b: 0)),  // red
      (32, RGB(r: 0, g: 170, b: 0)),  // green
      (33, RGB(r: 170, g: 85, b: 0)),  // yellow/brown
      (34, RGB(r: 0, g: 0, b: 170)),  // blue
      (35, RGB(r: 170, g: 0, b: 170)),  // magenta
      (36, RGB(r: 0, g: 170, b: 170)),  // cyan
      (37, RGB(r: 170, g: 170, b: 170)),  // white
      (90, RGB(r: 85, g: 85, b: 85)),  // bright black
      (91, RGB(r: 255, g: 85, b: 85)),  // bright red
      (92, RGB(r: 85, g: 255, b: 85)),  // bright green
      (93, RGB(r: 255, g: 255, b: 85)),  // bright yellow
      (94, RGB(r: 85, g: 85, b: 255)),  // bright blue
      (95, RGB(r: 255, g: 85, b: 255)),  // bright magenta
      (96, RGB(r: 85, g: 255, b: 255)),  // bright cyan
      (97, RGB(r: 255, g: 255, b: 255)),  // bright white
    ]

    var bestCode: UInt8 = 37
    var bestDistance = Int.max

    for (code, ref) in ansi16Colors {
      let dr = Int(rgb.r) - Int(ref.r)
      let dg = Int(rgb.g) - Int(ref.g)
      let db = Int(rgb.b) - Int(ref.b)
      let dist = dr * dr + dg * dg + db * db
      if dist < bestDistance {
        bestDistance = dist
        bestCode = code
      }
    }

    return bestCode
  }
}
