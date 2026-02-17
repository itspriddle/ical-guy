import Foundation
import XCTest

@testable import ICalGuyKit

// MARK: - UID Template Rendering Tests

final class UidDisplayRenderingTests: XCTestCase {
  private let testCalendar = CalendarInfo(
    id: "cal-1",
    title: "Work",
    type: "calDAV",
    source: "iCloud",
    color: "#1BADF8"
  )

  private func makeEvent(id: String = "evt-123") -> CalendarEvent {
    CalendarEvent(
      id: id,
      title: "Test Event",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: nil,
      notes: nil,
      url: nil,
      calendar: testCalendar,
      status: "confirmed"
    )
  }

  func testUidShownWhenEnabled() throws {
    let options = TextFormatterOptions(showUid: true)
    let formatter = try TemplateFormatter(
      options: options, colorizer: nil
    )
    let output = try formatter.formatEvents([makeEvent()])
    XCTAssertTrue(
      output.contains("UID:"),
      "Output should contain UID label when showUid is true"
    )
    XCTAssertTrue(
      output.contains("evt-123"),
      "Output should contain the event ID"
    )
  }

  func testUidHiddenByDefault() throws {
    let formatter = try TemplateFormatter(colorizer: nil)
    let output = try formatter.formatEvents([makeEvent()])
    XCTAssertFalse(
      output.contains("UID:"),
      "Output should not contain UID label by default"
    )
    XCTAssertFalse(
      output.contains("evt-123"),
      "Output should not contain the event ID by default"
    )
  }

  func testUidHiddenWhenExplicitlyDisabled() throws {
    let options = TextFormatterOptions(showUid: false)
    let formatter = try TemplateFormatter(
      options: options, colorizer: nil
    )
    let output = try formatter.formatEvents([makeEvent()])
    XCTAssertFalse(
      output.contains("UID:"),
      "Output should not contain UID label when showUid is false"
    )
  }

  func testUidAppearsAfterOtherDetails() throws {
    let options = TextFormatterOptions(
      showLocation: true, showUid: true
    )
    let event = CalendarEvent(
      id: "evt-456",
      title: "Meeting",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: "Room A",
      notes: nil,
      url: nil,
      calendar: testCalendar,
      status: "confirmed"
    )
    let formatter = try TemplateFormatter(
      options: options, colorizer: nil
    )
    let output = try formatter.formatEvents([event])
    let lines = output.components(separatedBy: "\n")

    // UID line should be after location line
    let locationIndex = lines.firstIndex { $0.contains("Location:") }
    let uidIndex = lines.firstIndex { $0.contains("UID:") }
    XCTAssertNotNil(locationIndex)
    XCTAssertNotNil(uidIndex)
    XCTAssertGreaterThan(uidIndex!, locationIndex!)
  }

  func testUidWithDateGrouping() throws {
    let options = TextFormatterOptions(showUid: true)
    let grouping = GroupingContext(mode: .date)
    let formatter = try TemplateFormatter(
      options: options, colorizer: nil, grouping: grouping
    )
    let output = try formatter.formatEvents([makeEvent()])
    XCTAssertTrue(output.contains("evt-123"))
  }

  func testUidWithCalendarGrouping() throws {
    let options = TextFormatterOptions(showUid: true)
    let grouping = GroupingContext(mode: .calendar)
    let formatter = try TemplateFormatter(
      options: options, colorizer: nil, grouping: grouping
    )
    let output = try formatter.formatEvents([makeEvent()])
    XCTAssertTrue(output.contains("evt-123"))
  }
}

// MARK: - Config Integration Tests

final class UidDisplayConfigTests: XCTestCase {
  func testUserConfigShowUidField() {
    let config = UserConfig(showUid: true)
    XCTAssertEqual(config.showUid, true)
  }

  func testUserConfigShowUidDefaultNil() {
    let config = UserConfig()
    XCTAssertNil(config.showUid)
  }

  func testRuntimeOptionsShowUidFromConfig() throws {
    let config = UserConfig(showUid: true)
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)
    XCTAssertTrue(opts.textOptions.showUid)
  }

  func testRuntimeOptionsShowUidDefaultFalse() throws {
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertFalse(opts.textOptions.showUid)
  }

  func testRuntimeOptionsShowUidFromCLI() throws {
    let cli = CLIOptions(showUid: true)
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertTrue(opts.textOptions.showUid)
  }

  func testCLIShowUidOverridesConfig() throws {
    let config = UserConfig(showUid: false)
    let cli = CLIOptions(showUid: true)
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)
    XCTAssertTrue(opts.textOptions.showUid)
  }

  func testTextFormatterOptionsShowUidDefault() {
    let options = TextFormatterOptions()
    XCTAssertFalse(options.showUid)
  }

  func testCLIOptionsShowUidDefault() {
    let cli = CLIOptions()
    XCTAssertFalse(cli.showUid)
  }
}
