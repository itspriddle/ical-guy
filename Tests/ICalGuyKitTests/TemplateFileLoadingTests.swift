import Foundation
import Mustache
import XCTest

@testable import ICalGuyKit

private let testCalendar = CalendarInfo(
  id: "cal-1",
  title: "Work",
  type: "calDAV",
  source: "iCloud",
  color: "#1BADF8"
)

private func makeEvent(
  id: String = "evt-1",
  title: String = "Team Standup",
  start: TimeInterval = 1_710_500_400,
  end: TimeInterval = 1_710_502_200,
  isAllDay: Bool = false,
  location: String? = nil,
  calendar: CalendarInfo = testCalendar
) -> CalendarEvent {
  CalendarEvent(
    id: id,
    title: title,
    startDate: Date(timeIntervalSince1970: start),
    endDate: Date(timeIntervalSince1970: end),
    isAllDay: isAllDay,
    location: location,
    notes: nil,
    url: nil,
    meetingUrl: nil,
    calendar: calendar,
    attendees: [],
    organizer: nil,
    recurrence: RecurrenceInfo(isRecurring: false, description: nil),
    status: "confirmed",
    availability: "busy"
  )
}

// MARK: - UserConfig Template File Fields

final class UserConfigTemplateFileFieldTests: XCTestCase {
  func testUserConfigCarriesTemplateFileFields() {
    let config = UserConfig(
      eventTemplateFile: "event.mustache",
      dateHeaderTemplateFile: "date-header.mustache",
      calendarHeaderTemplateFile: "cal-header.mustache"
    )
    XCTAssertEqual(config.eventTemplateFile, "event.mustache")
    XCTAssertEqual(
      config.dateHeaderTemplateFile, "date-header.mustache"
    )
    XCTAssertEqual(
      config.calendarHeaderTemplateFile, "cal-header.mustache"
    )
  }

  func testUserConfigTemplateFileFieldsDefaultToNil() {
    let config = UserConfig()
    XCTAssertNil(config.eventTemplateFile)
    XCTAssertNil(config.dateHeaderTemplateFile)
    XCTAssertNil(config.calendarHeaderTemplateFile)
  }
}

// MARK: - Template File Loading

final class TemplateFileLoadingTests: XCTestCase {
  private var tempDir: String!

  override func setUp() {
    super.setUp()
    tempDir =
      NSTemporaryDirectory()
      + "ical-guy-test-\(UUID().uuidString)"
    try? FileManager.default.createDirectory(
      atPath: tempDir,
      withIntermediateDirectories: true
    )
  }

  override func tearDown() {
    try? FileManager.default.removeItem(atPath: tempDir)
    super.tearDown()
  }

  private func writeTemplateFile(
    _ name: String, content: String
  ) -> String {
    let path = "\(tempDir!)/\(name)"
    try? content.write(
      toFile: path, atomically: true, encoding: .utf8
    )
    return path
  }

  func testAbsolutePathLoadsTemplateFile() throws {
    let path = writeTemplateFile(
      "event.mustache", content: "  {{title}}"
    )
    let config = UserConfig(eventTemplateFile: path)
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    XCTAssertNotNil(opts.eventTemplate)

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertEqual(result, "  Team Standup")
  }

  func testRelativePathResolvesFromTemplateBaseDir() throws {
    let baseDir = RuntimeOptions.templateBaseDirectory
    let templatesDir = baseDir
    try FileManager.default.createDirectory(
      atPath: templatesDir,
      withIntermediateDirectories: true
    )

    let filePath = "\(templatesDir)/test-relative.mustache"
    try "  {{title}} (relative)".write(
      toFile: filePath, atomically: true, encoding: .utf8
    )
    defer { try? FileManager.default.removeItem(atPath: filePath) }

    let config = UserConfig(
      eventTemplateFile: "test-relative.mustache"
    )
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertEqual(result, "  Team Standup (relative)")
  }

  func testMissingTemplateFileThrowsError() {
    let config = UserConfig(
      eventTemplateFile: "/nonexistent/path/event.mustache"
    )
    let cli = CLIOptions()

    XCTAssertThrowsError(
      try RuntimeOptions.resolve(config: config, cli: cli)
    ) { error in
      guard let configError = error as? ConfigError else {
        XCTFail("Expected ConfigError, got \(type(of: error))")
        return
      }
      let message = configError.errorDescription ?? ""
      XCTAssertTrue(
        message.contains("event"),
        "Error should mention template name: \(message)"
      )
      XCTAssertTrue(
        message.contains("/nonexistent/path/event.mustache"),
        "Error should include resolved path: \(message)"
      )
    }
  }

  func testMissingRelativeTemplateFileShowsResolvedPath() {
    let config = UserConfig(
      eventTemplateFile: "missing.mustache"
    )
    let cli = CLIOptions()

    XCTAssertThrowsError(
      try RuntimeOptions.resolve(config: config, cli: cli)
    ) { error in
      guard let configError = error as? ConfigError else {
        XCTFail("Expected ConfigError, got \(type(of: error))")
        return
      }
      let message = configError.errorDescription ?? ""
      XCTAssertTrue(
        message.contains("ical-guy/templates/missing.mustache"),
        "Error should show resolved path: \(message)"
      )
    }
  }

  func testFileTemplateTakesPrecedenceOverInline() throws {
    let path = writeTemplateFile(
      "event.mustache", content: "  file: {{title}}"
    )
    let config = UserConfig(
      eventTemplate: "  inline: {{title}}",
      eventTemplateFile: path
    )
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertEqual(
      result, "  file: Team Standup",
      "File template should take precedence over inline"
    )
  }

  func testDateHeaderFileTemplate() throws {
    let path = writeTemplateFile(
      "date-header.mustache", content: "=== {{formattedDate}} ==="
    )
    let config = UserConfig(dateHeaderTemplateFile: path)
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let grouping = GroupingContext(mode: .date)
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      grouping: grouping,
      dateHeaderTemplate: opts.dateHeaderTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    let firstLine = result.split(separator: "\n")
      .first.map(String.init)
    XCTAssertTrue(
      firstLine?.hasPrefix("===") ?? false,
      "Should use file template: \(firstLine ?? "")"
    )
  }

  func testCalendarHeaderFileTemplate() throws {
    let path = writeTemplateFile(
      "cal-header.mustache", content: ">> {{title}} <<"
    )
    let config = UserConfig(calendarHeaderTemplateFile: path)
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let grouping = GroupingContext(mode: .calendar)
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      grouping: grouping,
      calendarHeaderTemplate: opts.calendarHeaderTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    let firstLine = result.split(separator: "\n")
      .first.map(String.init)
    XCTAssertEqual(firstLine, ">> Work <<")
  }

  func testInvalidTemplateFileSyntaxThrowsError() throws {
    let path = writeTemplateFile(
      "bad.mustache", content: "{{#unclosed}"
    )
    let config = UserConfig(eventTemplateFile: path)
    let cli = CLIOptions()

    XCTAssertThrowsError(
      try RuntimeOptions.resolve(config: config, cli: cli)
    ) { error in
      guard let configError = error as? ConfigError else {
        XCTFail("Expected ConfigError, got \(type(of: error))")
        return
      }
      let message = configError.errorDescription ?? ""
      XCTAssertTrue(
        message.contains("Invalid Mustache syntax"),
        "Error should describe the problem: \(message)"
      )
      XCTAssertTrue(
        message.contains("event"),
        "Error should mention template name: \(message)"
      )
    }
  }

  func testUTF8FileEncoding() throws {
    let path = writeTemplateFile(
      "utf8.mustache", content: "  📅 {{title}} — {{calendar.title}}"
    )
    let config = UserConfig(eventTemplateFile: path)
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertEqual(result, "  📅 Team Standup — Work")
  }

  func testInlineUsedWhenNoFileSpecified() throws {
    let config = UserConfig(eventTemplate: "  inline: {{title}}")
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertEqual(result, "  inline: Team Standup")
  }

  func testDefaultUsedWhenNeitherFileNorInline() throws {
    let config = UserConfig(format: "text")
    let cli = CLIOptions(noColor: true)
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let formatter = try opts.makeFormatter(isTTY: false)
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("[Work]"))
  }
}
