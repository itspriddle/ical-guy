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
  start: TimeInterval = 1_710_500_400,  // 2024-03-15 14:00 UTC
  end: TimeInterval = 1_710_502_200,  // 2024-03-15 14:30 UTC
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

// MARK: - UserConfig Template Fields

final class UserConfigTemplateFieldTests: XCTestCase {
  func testUserConfigCarriesTemplateStrings() {
    let config = UserConfig(
      eventTemplate: "{{title}}",
      dateHeaderTemplate: "{{formattedDate}}",
      calendarHeaderTemplate: "{{title}}"
    )
    XCTAssertEqual(config.eventTemplate, "{{title}}")
    XCTAssertEqual(config.dateHeaderTemplate, "{{formattedDate}}")
    XCTAssertEqual(config.calendarHeaderTemplate, "{{title}}")
  }

  func testUserConfigTemplateFieldsDefaultToNil() {
    let config = UserConfig()
    XCTAssertNil(config.eventTemplate)
    XCTAssertNil(config.dateHeaderTemplate)
    XCTAssertNil(config.calendarHeaderTemplate)
  }
}

// MARK: - RuntimeOptions Template Compilation

final class RuntimeOptionsTemplateTests: XCTestCase {
  func testResolvesNilTemplatesWhenNotConfigured() throws {
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)

    XCTAssertNil(opts.eventTemplate)
    XCTAssertNil(opts.dateHeaderTemplate)
    XCTAssertNil(opts.calendarHeaderTemplate)
  }

  func testCompilesValidEventTemplate() throws {
    let config = UserConfig(eventTemplate: "{{title}}")
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    XCTAssertNotNil(opts.eventTemplate)
  }

  func testCompilesValidDateHeaderTemplate() throws {
    let config = UserConfig(dateHeaderTemplate: "{{formattedDate}}")
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    XCTAssertNotNil(opts.dateHeaderTemplate)
  }

  func testCompilesValidCalendarHeaderTemplate() throws {
    let config = UserConfig(calendarHeaderTemplate: "{{title}}")
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    XCTAssertNotNil(opts.calendarHeaderTemplate)
  }

  func testInvalidEventTemplateThrowsConfigError() {
    let config = UserConfig(eventTemplate: "{{#unclosed}")
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
        message.contains("Invalid Mustache syntax"),
        "Error should describe the problem: \(message)"
      )
    }
  }

  func testInvalidDateHeaderTemplateThrowsConfigError() {
    let config = UserConfig(dateHeaderTemplate: "{{#bad}")
    let cli = CLIOptions()

    XCTAssertThrowsError(
      try RuntimeOptions.resolve(config: config, cli: cli)
    ) { error in
      guard let configError = error as? ConfigError else {
        XCTFail("Expected ConfigError")
        return
      }
      let message = configError.errorDescription ?? ""
      XCTAssertTrue(message.contains("date-header"))
    }
  }

  func testInvalidCalendarHeaderTemplateThrowsConfigError() {
    let config = UserConfig(calendarHeaderTemplate: "{{#bad}")
    let cli = CLIOptions()

    XCTAssertThrowsError(
      try RuntimeOptions.resolve(config: config, cli: cli)
    ) { error in
      guard let configError = error as? ConfigError else {
        XCTFail("Expected ConfigError")
        return
      }
      let message = configError.errorDescription ?? ""
      XCTAssertTrue(message.contains("calendar-header"))
    }
  }
}

// MARK: - Template Rendering via Config

final class TemplateConfigRenderingTests: XCTestCase {
  func testCustomEventTemplateRendersTitle() throws {
    let config = UserConfig(eventTemplate: "  {{title}}")
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      textOptions: opts.textOptions,
      dateFormats: opts.dateFormats,
      eventTemplate: opts.eventTemplate
    )

    let event = makeEvent()
    let result = try formatter.formatEvents([event])
    XCTAssertEqual(result, "  Team Standup")
  }

  func testCustomEventTemplateWithMultipleFields() throws {
    let templateStr = "  {{startTime}} - {{title}} ({{calendar.title}})"
    let config = UserConfig(eventTemplate: templateStr)
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      textOptions: opts.textOptions,
      dateFormats: opts.dateFormats,
      eventTemplate: opts.eventTemplate
    )

    let event = makeEvent()
    let result = try formatter.formatEvents([event])
    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("Work"))
    XCTAssertTrue(result.contains(":"))
  }

  func testCustomDateHeaderTemplate() throws {
    let config = UserConfig(
      dateHeaderTemplate: "--- {{formattedDate}} ---"
    )
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let grouping = GroupingContext(mode: .date)
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      grouping: grouping,
      dateFormats: opts.dateFormats,
      dateHeaderTemplate: opts.dateHeaderTemplate
    )

    let event = makeEvent()
    let result = try formatter.formatEvents([event])
    let firstLine = result.split(separator: "\n").first.map(String.init)
    XCTAssertTrue(
      firstLine?.hasPrefix("---") ?? false,
      "Date header should use custom template, got: \(firstLine ?? "")"
    )
    XCTAssertTrue(
      firstLine?.hasSuffix("---") ?? false,
      "Date header should use custom template, got: \(firstLine ?? "")"
    )
  }

  func testCustomCalendarHeaderTemplate() throws {
    let config = UserConfig(
      calendarHeaderTemplate: "== {{title}} =="
    )
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let grouping = GroupingContext(mode: .calendar)
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      grouping: grouping,
      dateFormats: opts.dateFormats,
      calendarHeaderTemplate: opts.calendarHeaderTemplate
    )

    let event = makeEvent()
    let result = try formatter.formatEvents([event])
    let firstLine = result.split(separator: "\n").first.map(String.init)
    XCTAssertEqual(firstLine, "== Work ==")
  }

  func testMultiLineEventTemplate() throws {
    let templateStr = [
      "  {{title}}",
      "{{#hasLocation}}",
      "    Location: {{location}}",
      "{{/hasLocation}}",
    ].joined(separator: "\n")

    let config = UserConfig(eventTemplate: templateStr)
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true,
      textOptions: opts.textOptions,
      dateFormats: opts.dateFormats,
      eventTemplate: opts.eventTemplate
    )

    let event = makeEvent(location: "Room 42")
    let result = try formatter.formatEvents([event])
    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("Location: Room 42"))
  }

  func testMakeFormatterPassesConfigTemplates() throws {
    let config = UserConfig(
      format: "text", eventTemplate: "  {{title}} only"
    )
    let cli = CLIOptions(noColor: true)
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    let formatter = try opts.makeFormatter(isTTY: false)
    let event = makeEvent()
    let result = try formatter.formatEvents([event])
    XCTAssertEqual(result, "  Team Standup only")
  }

  func testDefaultTemplateUsedWhenNoConfigTemplates() throws {
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
