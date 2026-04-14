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

  // MARK: - Value Parsing

  func testParsesScalarsFromEachSection() throws {
    let content = """
      [defaults]
      format = "json"
      exclude-all-day = true
      group-by = "calendar"
      show-empty-dates = true
      include-calendars = ["Work", "Home"]

      [text]
      show-calendar = false
      show-uid = true

      [templates]
      time-format = "HH:mm"
      truncate-notes = 200

      [free]
      min-duration = 30
      work-start = "09:00"

      [browsers]
      default = "Safari"
      meet = "Chrome"
      """
    let path = makeConfigFile(name: "values", content: content)
    defer { cleanup(path) }

    let config = try XCTUnwrap(try ConfigLoader.load(from: path))
    XCTAssertEqual(config.format, "json")
    XCTAssertEqual(config.excludeAllDay, true)
    XCTAssertEqual(config.groupBy, "calendar")
    XCTAssertEqual(config.showEmptyDates, true)
    XCTAssertEqual(config.includeCalendars, ["Work", "Home"])
    XCTAssertEqual(config.showCalendar, false)
    XCTAssertEqual(config.showUid, true)
    XCTAssertEqual(config.timeFormat, "HH:mm")
    XCTAssertEqual(config.truncateNotes, 200)
    XCTAssertEqual(config.freeMinDuration, 30)
    XCTAssertEqual(config.freeWorkStart, "09:00")
    XCTAssertEqual(config.browsers?.defaultBrowser, "Safari")
    XCTAssertEqual(config.browsers?.meet, "Chrome")
  }

  // MARK: - Helpers

  private func makeConfigFile(name: String, content: String = "[defaults]\n") -> String {
    let dir = FileManager.default.temporaryDirectory.path
    let path = "\(dir)/ical-guy-\(name)-\(UUID().uuidString).toml"
    // swiftlint:disable:next force_try
    try! content.write(
      toFile: path, atomically: true, encoding: .utf8)
    return path
  }

  private func cleanup(_ path: String) {
    try? FileManager.default.removeItem(atPath: path)
  }
}
