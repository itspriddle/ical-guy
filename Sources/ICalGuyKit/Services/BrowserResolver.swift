import Foundation

public enum BrowserResolverError: Error, LocalizedError {
  case applicationNotFound(String)

  public var errorDescription: String? {
    switch self {
    case .applicationNotFound(let name):
      return "Application not found: \(name)"
    }
  }
}

public struct BrowserResolver: Sendable {
  public init() {}

  /// Resolves which browser to use based on the priority chain:
  /// CLI flag > vendor-specific config > default config > nil (system default)
  public func resolveBrowserName(
    cliBrowser: String?,
    vendor: MeetingVendor?,
    config: BrowserConfig?
  ) -> String? {
    if let cliBrowser {
      return cliBrowser
    }
    return config?.browser(for: vendor)
  }

  /// Resolves an application name to a file URL.
  /// Accepts bare names ("Google Chrome") or absolute paths ("/Applications/Firefox.app").
  public func resolveApplicationURL(_ name: String) -> Result<URL, BrowserResolverError> {
    // If it's an absolute path, check directly
    if name.hasPrefix("/") {
      let path = name.hasSuffix(".app") ? name : "\(name).app"
      if FileManager.default.fileExists(atPath: path) {
        return .success(URL(fileURLWithPath: path))
      }
      return .failure(.applicationNotFound(name))
    }

    let appName = name.hasSuffix(".app") ? name : "\(name).app"
    let searchPaths = [
      "/Applications",
      "\(NSHomeDirectory())/Applications",
      "/System/Applications",
    ]

    for dir in searchPaths {
      let path = "\(dir)/\(appName)"
      if FileManager.default.fileExists(atPath: path) {
        return .success(URL(fileURLWithPath: path))
      }
    }

    return .failure(.applicationNotFound(name))
  }
}
