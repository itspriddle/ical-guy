import Foundation

public enum TerminalColorCapability: Sendable {
  case none
  case ansi16
  case ansi256
  case truecolor
}

public struct ANSIColorizer: Sendable {
  public let capability: TerminalColorCapability

  public init(capability: TerminalColorCapability) {
    self.capability = capability
  }

  /// Detect terminal color capability from environment.
  /// Returns nil if colors should be disabled (NO_COLOR, not a TTY, etc.).
  public static func detect(
    isTTY: Bool,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) -> ANSIColorizer? {
    if environment["NO_COLOR"] != nil { return nil }
    if !isTTY { return nil }

    if let ct = environment["COLORTERM"]?.lowercased(), ct == "truecolor" || ct == "24bit" {
      return ANSIColorizer(capability: .truecolor)
    }

    if let term = environment["TERM"]?.lowercased(), term.contains("256color") {
      return ANSIColorizer(capability: .ansi256)
    }

    return ANSIColorizer(capability: .ansi16)
  }

  /// Wrap text with ANSI foreground color escape codes for the given hex color.
  public func colorize(_ text: String, hexColor: String) -> String {
    guard capability != .none else { return text }
    guard let rgb = ColorConversion.hexToRGB(hexColor) else { return text }

    let code: String
    switch capability {
    case .truecolor:
      code = "\u{1B}[38;2;\(rgb.r);\(rgb.g);\(rgb.b)m"
    case .ansi256:
      let index = ColorConversion.rgbToANSI256(rgb)
      code = "\u{1B}[38;5;\(index)m"
    case .ansi16:
      let ansiCode = ColorConversion.rgbToANSI16(rgb)
      code = "\u{1B}[\(ansiCode)m"
    case .none:
      return text
    }

    return "\(code)\(text)\u{1B}[0m"
  }

  /// Apply bold formatting.
  public func bold(_ text: String) -> String {
    guard capability != .none else { return text }
    return "\u{1B}[1m\(text)\u{1B}[0m"
  }

  /// Apply dim formatting.
  public func dim(_ text: String) -> String {
    guard capability != .none else { return text }
    return "\u{1B}[2m\(text)\u{1B}[0m"
  }
}
