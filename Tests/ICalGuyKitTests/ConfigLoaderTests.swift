import Foundation
import XCTest

@testable import ICalGuyKit

final class ConfigLoaderTests: XCTestCase {

  // MARK: - Path Resolution

  func testExplicitPathLoadsFile() throws {
    let configPath = makeConfigFile(name: "explicit")
    defer { cleanup(configPath) }

    let config = try ConfigLoader.load(from: configPath)
    XCTAssertNotNil(config)
  }

  func testMissingExplicitPathReturnsNil() throws {
    let config = try ConfigLoader.load(
      from: "/tmp/nonexistent-ical-guy-config.toml")
    XCTAssertNil(config)
  }

  func testEnvVarFallbackLoadsFile() throws {
    let configPath = makeConfigFile(name: "envvar")
    defer {
      cleanup(configPath)
      unsetenv("ICAL_GUY_CONFIG")
    }

    setenv("ICAL_GUY_CONFIG", configPath, 1)

    let config = try ConfigLoader.load()
    XCTAssertNotNil(config)
  }

  func testExplicitPathTakesPrecedenceOverEnvVar() throws {
    let envPath = makeConfigFile(name: "env-precedence")
    let explicitPath = makeConfigFile(name: "explicit-precedence")
    let missingPath = "/tmp/nonexistent-ical-guy-config.toml"
    defer {
      cleanup(envPath)
      cleanup(explicitPath)
      unsetenv("ICAL_GUY_CONFIG")
    }

    // Set env var to a valid file, but pass a missing explicit path
    setenv("ICAL_GUY_CONFIG", envPath, 1)

    // Explicit path wins even if env var points to a valid file
    let config = try ConfigLoader.load(from: missingPath)
    XCTAssertNil(config)
  }

  func testEnvVarIgnoredWhenExplicitPathProvided() throws {
    let envPath = "/tmp/nonexistent-env-config.toml"
    let explicitPath = makeConfigFile(name: "explicit-wins")
    defer {
      cleanup(explicitPath)
      unsetenv("ICAL_GUY_CONFIG")
    }

    // Set env var to nonexistent file
    setenv("ICAL_GUY_CONFIG", envPath, 1)

    // Explicit path should be used, ignoring env var
    let config = try ConfigLoader.load(from: explicitPath)
    XCTAssertNotNil(config)
  }

  // MARK: - Helpers

  private func makeConfigFile(name: String) -> String {
    let dir = FileManager.default.temporaryDirectory.path
    let path = "\(dir)/ical-guy-\(name)-\(UUID().uuidString).toml"
    let content = "[defaults]\n"
    // swiftlint:disable:next force_try
    try! content.write(
      toFile: path, atomically: true, encoding: .utf8)
    return path
  }

  private func cleanup(_ path: String) {
    try? FileManager.default.removeItem(atPath: path)
  }
}
