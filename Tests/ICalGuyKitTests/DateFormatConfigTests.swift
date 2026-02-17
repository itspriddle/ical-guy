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
  calendar: CalendarInfo = testCalendar
) -> CalendarEvent {
  CalendarEvent(
    id: id,
    title: title,
    startDate: Date(timeIntervalSince1970: start),
    endDate: Date(timeIntervalSince1970: end),
    isAllDay: isAllDay,
    location: nil,
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

// MARK: - Custom Date/Time Format Tests

final class DateFormatConfigTests: XCTestCase {
  func test24HourTimeFormat() throws {
    let formats = TemplateDateFormats(timeFormat: "HH:mm")
    let formatter = try TemplateFormatter(dateFormats: formats)
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    XCTAssertFalse(result.contains("AM"))
    XCTAssertFalse(result.contains("PM"))
    XCTAssertTrue(result.contains(":"))
  }

  func testCustomDateFormatInEventContext() throws {
    let formats = TemplateDateFormats(
      timeFormat: "HH:mm",
      dateFormat: "yyyy-MM-dd"
    )
    let template = try MustacheTemplate(
      string: "  {{startTime}} {{startDate}} {{title}}"
    )
    let formatter = try TemplateFormatter(
      eventTemplate: template, dateFormats: formats
    )
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("2024-"))
    XCTAssertFalse(result.contains("AM"))
    XCTAssertFalse(result.contains("PM"))
  }

  func testCustomDateFormatInDateGroupHeader() throws {
    let formats = TemplateDateFormats(dateFormat: "yyyy-MM-dd")
    let grouping = GroupingContext(mode: .date)
    let formatter = try TemplateFormatter(
      grouping: grouping, dateFormats: formats
    )
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    let firstLine = String(result.split(separator: "\n")[0])
    XCTAssertTrue(
      firstLine.contains("2024-03"),
      "Date header should use custom format, got: \(firstLine)"
    )
  }

  func testDefaultFormatsMatchExpected() throws {
    let formatter = try TemplateFormatter()
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    // Default time format is "h:mm a"
    XCTAssertTrue(
      result.contains("AM") || result.contains("PM"),
      "Default format should use 12-hour time: \(result)"
    )
    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("[Work]"))
  }

  func testCustomTimeFormatWithDateGrouping() throws {
    let formats = TemplateDateFormats(timeFormat: "HH:mm")
    let grouping = GroupingContext(mode: .date)
    let formatter = try TemplateFormatter(
      grouping: grouping, dateFormats: formats
    )
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    XCTAssertFalse(result.contains("AM"))
    XCTAssertFalse(result.contains("PM"))
  }

  func testAllDayEventIgnoresTimeFormat() throws {
    let formats = TemplateDateFormats(timeFormat: "HH:mm")
    let formatter = try TemplateFormatter(dateFormats: formats)
    let event = makeEvent(isAllDay: true)
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("All day"))
  }

  func testFormatterFactoryPassesDateFormats() throws {
    let formats = TemplateDateFormats(timeFormat: "HH:mm")
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: false, noColor: true, dateFormats: formats
    )
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    XCTAssertFalse(result.contains("AM"))
    XCTAssertFalse(result.contains("PM"))
  }

  func testRuntimeOptionsResolvesDateFormats() throws {
    let config = UserConfig(timeFormat: "HH:mm", dateFormat: "dd/MM/yyyy")
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    XCTAssertEqual(opts.dateFormats.timeFormat, "HH:mm")
    XCTAssertEqual(opts.dateFormats.dateFormat, "dd/MM/yyyy")
  }

  func testCLIOverridesConfigDateFormats() throws {
    let config = UserConfig(timeFormat: "HH:mm", dateFormat: "dd/MM/yyyy")
    let cli = CLIOptions(timeFormat: "h:mm a", dateFormat: "EEEE, MMM d")
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    XCTAssertEqual(opts.dateFormats.timeFormat, "h:mm a")
    XCTAssertEqual(opts.dateFormats.dateFormat, "EEEE, MMM d")
  }

  func testDefaultDateFormatsWhenNoneConfigured() throws {
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)

    XCTAssertEqual(opts.dateFormats.timeFormat, "h:mm a")
    XCTAssertEqual(opts.dateFormats.dateFormat, "EEEE, MMM d, yyyy")
  }

  func testUserConfigCarriesDateFormats() {
    let config = UserConfig(timeFormat: "HH:mm", dateFormat: "dd/MM/yyyy")
    XCTAssertEqual(config.timeFormat, "HH:mm")
    XCTAssertEqual(config.dateFormat, "dd/MM/yyyy")
  }

  func testUserConfigDateFormatsDefaultToNil() {
    let config = UserConfig()
    XCTAssertNil(config.timeFormat)
    XCTAssertNil(config.dateFormat)
  }
}
