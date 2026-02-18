import XCTest

@testable import ICalGuyKit

final class RuntimeOptionsTests: XCTestCase {

  // MARK: - Hide Flag

  func testHideSingleProperty() throws {
    let cli = CLIOptions(hide: ["calendar"])
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertFalse(opts.textOptions.showCalendar)
    XCTAssertTrue(opts.textOptions.showLocation)
    XCTAssertTrue(opts.textOptions.showAttendees)
    XCTAssertTrue(opts.textOptions.showMeetingUrl)
  }

  func testHideMultipleProperties() throws {
    let cli = CLIOptions(hide: ["calendar", "notes", "attendees"])
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertFalse(opts.textOptions.showCalendar)
    XCTAssertFalse(opts.textOptions.showAttendees)
    XCTAssertFalse(opts.textOptions.showNotes)
    XCTAssertTrue(opts.textOptions.showLocation)
    XCTAssertTrue(opts.textOptions.showMeetingUrl)
  }

  func testHideOverridesConfigTrue() throws {
    let config = UserConfig(showCalendar: true)
    let cli = CLIOptions(hide: ["calendar"])
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)
    XCTAssertFalse(opts.textOptions.showCalendar)
  }

  func testHideMeetingUrl() throws {
    let cli = CLIOptions(hide: ["meeting-url"])
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertFalse(opts.textOptions.showMeetingUrl)
  }

  func testHideUidOverridesShowUidFlag() throws {
    let cli = CLIOptions(showUid: true, hide: ["uid"])
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertFalse(opts.textOptions.showUid)
  }

  func testHideIsCaseInsensitive() throws {
    let cli = CLIOptions(hide: ["Calendar", "LOCATION"])
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertFalse(opts.textOptions.showCalendar)
    XCTAssertFalse(opts.textOptions.showLocation)
  }

  func testHideUnknownPropertyIsIgnored() throws {
    let cli = CLIOptions(hide: ["nonexistent"])
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertTrue(opts.textOptions.showCalendar)
    XCTAssertTrue(opts.textOptions.showLocation)
    XCTAssertTrue(opts.textOptions.showAttendees)
    XCTAssertTrue(opts.textOptions.showMeetingUrl)
  }

  func testNoHidePreservesDefaults() throws {
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertTrue(opts.textOptions.showCalendar)
    XCTAssertTrue(opts.textOptions.showLocation)
    XCTAssertTrue(opts.textOptions.showAttendees)
    XCTAssertTrue(opts.textOptions.showMeetingUrl)
    XCTAssertFalse(opts.textOptions.showNotes)
    XCTAssertFalse(opts.textOptions.showUid)
  }
}
