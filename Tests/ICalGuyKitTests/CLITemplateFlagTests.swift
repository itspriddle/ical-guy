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
    recurrence: RecurrenceInfo(
      isRecurring: false, description: nil
    ),
    status: "confirmed",
    availability: "busy"
  )
}

// MARK: - CLI Template Flag Tests

final class CLITemplateFlagTests: XCTestCase {
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

  func testCLITemplateFileRendersEvents() throws {
    let path = writeTemplateFile(
      "custom.mustache", content: "  CLI: {{title}}"
    )
    let cli = CLIOptions(templateFile: path)
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)

    XCTAssertNotNil(opts.eventTemplate)

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertEqual(result, "  CLI: Team Standup")
  }

  func testCLITemplateOverridesConfigInline() throws {
    let path = writeTemplateFile(
      "cli.mustache", content: "  cli: {{title}}"
    )
    let config = UserConfig(eventTemplate: "  inline: {{title}}")
    let cli = CLIOptions(templateFile: path)
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertEqual(
      result, "  cli: Team Standup",
      "CLI --template should override inline config template"
    )
  }

  func testCLITemplateOverridesConfigFile() throws {
    let cliPath = writeTemplateFile(
      "cli.mustache", content: "  cli: {{title}}"
    )
    let configPath = writeTemplateFile(
      "config.mustache", content: "  config-file: {{title}}"
    )
    let config = UserConfig(eventTemplateFile: configPath)
    let cli = CLIOptions(templateFile: cliPath)
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertEqual(
      result, "  cli: Team Standup",
      "CLI --template should override config file template"
    )
  }

  func testCLITemplateOverridesBothConfigFileAndInline() throws {
    let cliPath = writeTemplateFile(
      "cli.mustache", content: "  cli: {{title}}"
    )
    let configPath = writeTemplateFile(
      "config.mustache", content: "  config-file: {{title}}"
    )
    let config = UserConfig(
      eventTemplate: "  inline: {{title}}",
      eventTemplateFile: configPath
    )
    let cli = CLIOptions(templateFile: cliPath)
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertEqual(
      result, "  cli: Team Standup",
      "CLI should have highest precedence"
    )
  }

  func testMissingCLITemplateFileThrowsError() {
    let cli = CLIOptions(
      templateFile: "/nonexistent/cli-template.mustache"
    )

    XCTAssertThrowsError(
      try RuntimeOptions.resolve(config: nil, cli: cli)
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
        message.contains("cli-template.mustache"),
        "Error should include the path: \(message)"
      )
    }
  }

  func testInvalidCLITemplateSyntaxThrowsError() throws {
    let path = writeTemplateFile(
      "bad.mustache", content: "{{#unclosed}"
    )
    let cli = CLIOptions(templateFile: path)

    XCTAssertThrowsError(
      try RuntimeOptions.resolve(config: nil, cli: cli)
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

  func testCLITemplateWorksWithDateGrouping() throws {
    let path = writeTemplateFile(
      "grouped.mustache", content: "  {{title}}"
    )
    let cli = CLIOptions(templateFile: path)
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)

    let grouping = GroupingContext(mode: .date)
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      grouping: grouping,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertTrue(
      result.contains("Team Standup"),
      "Events should render with CLI template under date grouping"
    )
  }

  func testCLITemplateWorksWithCalendarGrouping() throws {
    let path = writeTemplateFile(
      "grouped.mustache", content: "  {{title}}"
    )
    let cli = CLIOptions(templateFile: path)
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)

    let grouping = GroupingContext(mode: .calendar)
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      grouping: grouping,
      eventTemplate: opts.eventTemplate
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertTrue(
      result.contains("Team Standup"),
      "Events should render with CLI template under cal grouping"
    )
  }

  func testCLIOptionsCarriesTemplateFile() {
    let cli = CLIOptions(templateFile: "/some/path.mustache")
    XCTAssertEqual(cli.templateFile, "/some/path.mustache")
  }

  func testCLIOptionsTemplateFileDefaultsToNil() {
    let cli = CLIOptions()
    XCTAssertNil(cli.templateFile)
  }

  // MARK: - CLI Decoration Override Tests

  func testCLIBulletOverridesConfig() throws {
    let config = UserConfig(bullet: "* ")
    let cli = CLIOptions(bullet: "→ ")
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )
    XCTAssertEqual(opts.decorations.bullet, "→ ")
  }

  func testCLISeparatorOverridesConfig() throws {
    let config = UserConfig(separator: "---")
    let cli = CLIOptions(separator: "===")
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )
    XCTAssertEqual(opts.decorations.separator, "===")
  }

  func testCLIIndentOverridesConfig() throws {
    let config = UserConfig(indent: "    ")
    let cli = CLIOptions(indent: "  ")
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )
    XCTAssertEqual(opts.decorations.indent, "  ")
  }

  func testCLITruncateNotesOverridesConfig() throws {
    let config = UserConfig(truncateNotes: 100)
    let cli = CLIOptions(truncateNotes: 50)
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )
    XCTAssertEqual(opts.truncation.notes, 50)
  }

  func testCLITruncateLocationOverridesConfig() throws {
    let config = UserConfig(truncateLocation: 80)
    let cli = CLIOptions(truncateLocation: 30)
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )
    XCTAssertEqual(opts.truncation.location, 30)
  }

  func testCLIDecorationDefaultsToConfig() throws {
    let config = UserConfig(
      bullet: "• ", separator: "---", indent: "  "
    )
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )
    XCTAssertEqual(opts.decorations.bullet, "• ")
    XCTAssertEqual(opts.decorations.separator, "---")
    XCTAssertEqual(opts.decorations.indent, "  ")
  }

  func testCLITruncationDefaultsToConfig() throws {
    let config = UserConfig(
      truncateNotes: 80, truncateLocation: 40
    )
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(
      config: config, cli: cli
    )
    XCTAssertEqual(opts.truncation.notes, 80)
    XCTAssertEqual(opts.truncation.location, 40)
  }

  func testCLIDecorationDefaultsWhenNoConfig() throws {
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertEqual(opts.decorations.bullet, "")
    XCTAssertEqual(opts.decorations.separator, "")
    XCTAssertEqual(opts.decorations.indent, "    ")
  }

  func testCLIBulletRendersInOutput() throws {
    let cli = CLIOptions(noColor: true, bullet: "→ ")
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      decorations: opts.decorations
    )
    let result = try formatter.formatEvents([makeEvent()])
    XCTAssertTrue(
      result.contains("→ "),
      "Output should contain CLI bullet: \(result)"
    )
  }

  func testCLISeparatorRendersInOutput() throws {
    let cli = CLIOptions(noColor: true, separator: "---")
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      decorations: opts.decorations
    )
    let events = [
      makeEvent(id: "evt-1", title: "Meeting 1"),
      makeEvent(id: "evt-2", title: "Meeting 2"),
    ]
    let result = try formatter.formatEvents(events)
    XCTAssertTrue(
      result.contains("---"),
      "Output should contain CLI separator: \(result)"
    )
  }
}
