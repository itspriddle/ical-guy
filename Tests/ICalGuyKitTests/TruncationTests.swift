import Foundation
import Mustache
import XCTest

@testable import ICalGuyKit

// MARK: - TruncationLimits Unit Tests

final class TruncationLimitsTests: XCTestCase {
  func testAttendeesPropertyDefaultsNil() {
    let limits = TruncationLimits()
    XCTAssertNil(limits.attendees)
  }

  func testAttendeesPropertySetInInit() {
    let limits = TruncationLimits(attendees: 5)
    XCTAssertEqual(limits.attendees, 5)
  }

  func testNoTruncationWhenLimitIsNil() {
    let result = TruncationLimits.truncate("Hello World", limit: nil)
    XCTAssertEqual(result, "Hello World")
  }

  func testNoTruncationWhenLimitIsZero() {
    let result = TruncationLimits.truncate("Hello World", limit: 0)
    XCTAssertEqual(result, "Hello World")
  }

  func testNoTruncationWhenTextShorterThanLimit() {
    let result = TruncationLimits.truncate("Hello", limit: 10)
    XCTAssertEqual(result, "Hello")
  }

  func testNoTruncationWhenTextEqualsLimit() {
    let result = TruncationLimits.truncate("Hello", limit: 5)
    XCTAssertEqual(result, "Hello")
  }

  func testTruncationAddsEllipsis() {
    let result = TruncationLimits.truncate("Hello World", limit: 8)
    XCTAssertEqual(result, "Hello...")
    XCTAssertEqual(result.count, 8)
  }

  func testEllipsisCountsTowardLimit() {
    let result = TruncationLimits.truncate("Conference Room B", limit: 10)
    XCTAssertEqual(result, "Confere...")
    XCTAssertEqual(result.count, 10)
  }

  func testLimitOfThreeProducesOnlyEllipsis() {
    let result = TruncationLimits.truncate("Hello World", limit: 3)
    XCTAssertEqual(result, "...")
  }

  func testLimitOfTwoProducesTwoDots() {
    let result = TruncationLimits.truncate("Hello World", limit: 2)
    XCTAssertEqual(result, "..")
  }

  func testLimitOfOneProducesOneDot() {
    let result = TruncationLimits.truncate("Hello World", limit: 1)
    XCTAssertEqual(result, ".")
  }

  func testLimitOfFour() {
    let result = TruncationLimits.truncate("Hello World", limit: 4)
    XCTAssertEqual(result, "H...")
    XCTAssertEqual(result.count, 4)
  }

  func testEmptyStringNotTruncated() {
    let result = TruncationLimits.truncate("", limit: 5)
    XCTAssertEqual(result, "")
  }

  func testNegativeLimitNoTruncation() {
    let result = TruncationLimits.truncate("Hello World", limit: -1)
    XCTAssertEqual(result, "Hello World")
  }
}

// MARK: - Context Integration Tests

final class TruncationContextTests: XCTestCase {
  private let testCalendar = CalendarInfo(
    id: "cal-1",
    title: "Work",
    type: "calDAV",
    source: "iCloud",
    color: "#1BADF8"
  )

  private func makeEvent(
    location: String? = nil, notes: String? = nil,
    attendees: [Attendee] = []
  ) -> CalendarEvent {
    CalendarEvent(
      id: "evt-1",
      title: "Test Event",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: location,
      notes: notes,
      url: nil,
      calendar: testCalendar,
      attendees: attendees,
      status: "confirmed"
    )
  }

  private func makeAttendees(count: Int) -> [Attendee] {
    (0..<count).map { i in
      Attendee(
        name: "Person \(i)",
        email: "person\(i)@example.com",
        status: .accepted,
        role: .required,
        isCurrentUser: i == 0
      )
    }
  }

  func testNotesTruncatedInContext() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(notes: 10)
    )
    let event = makeEvent(notes: "This is a very long note")
    let context = ctx.buildContext(for: event)

    XCTAssertEqual(context["notes"] as? String, "This is...")
  }

  func testLocationTruncatedInContext() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(location: 12)
    )
    let event = makeEvent(location: "Conference Room Building A")
    let context = ctx.buildContext(for: event)

    XCTAssertEqual(context["location"] as? String, "Conferenc...")
  }

  func testNoTruncationWithDefaultLimits() {
    let ctx = EventTemplateContext()
    let longText = String(repeating: "x", count: 1000)
    let event = makeEvent(location: longText, notes: longText)
    let context = ctx.buildContext(for: event)

    XCTAssertEqual(context["location"] as? String, longText)
    XCTAssertEqual(context["notes"] as? String, longText)
  }

  func testZeroLimitMeansNoTruncation() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(notes: 0, location: 0)
    )
    let event = makeEvent(
      location: "Very Long Location Name",
      notes: "Very Long Notes Text"
    )
    let context = ctx.buildContext(for: event)

    XCTAssertEqual(
      context["location"] as? String, "Very Long Location Name"
    )
    XCTAssertEqual(context["notes"] as? String, "Very Long Notes Text")
  }

  func testNilFieldsStayEmptyWithTruncation() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(notes: 5, location: 5)
    )
    let event = makeEvent(location: nil, notes: nil)
    let context = ctx.buildContext(for: event)

    XCTAssertEqual(context["location"] as? String, "")
    XCTAssertEqual(context["notes"] as? String, "")
  }

  func testBooleanFlagsUnaffectedByTruncation() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(notes: 5, location: 5)
    )
    let event = makeEvent(
      location: "Conference Room", notes: "Some notes"
    )
    let context = ctx.buildContext(for: event)

    XCTAssertEqual(context["hasLocation"] as? Bool, true)
    XCTAssertEqual(context["hasNotes"] as? Bool, true)
  }

  func testTruncationInMustacheTemplate() throws {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(notes: 10, location: 8)
    )
    let event = makeEvent(
      location: "Conference Room B",
      notes: "Weekly sync meeting"
    )
    let context = ctx.buildContext(for: event)

    let template = try MustacheTemplate(
      string: "{{location}} | {{notes}}"
    )
    let result = template.render(context)
    XCTAssertEqual(result, "Confe... | Weekly ...")
  }

  // MARK: - Attendees Truncation Tests

  func testAttendeesNotTruncatedWhenLimitNil() {
    let ctx = EventTemplateContext()
    let event = makeEvent(attendees: makeAttendees(count: 5))
    let context = ctx.buildContext(for: event)

    let attendees = context["attendees"] as? [[String: Any]]
    XCTAssertEqual(attendees?.count, 5)
    XCTAssertEqual(context["attendeesTotalCount"] as? Int, 5)
    XCTAssertEqual(context["hasAttendeesOverflow"] as? Bool, false)
    XCTAssertEqual(context["attendeesOverflowCount"] as? Int, 0)
  }

  func testAttendeesNotTruncatedWhenBelowLimit() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(attendees: 5)
    )
    let event = makeEvent(attendees: makeAttendees(count: 2))
    let context = ctx.buildContext(for: event)

    let attendees = context["attendees"] as? [[String: Any]]
    XCTAssertEqual(attendees?.count, 2)
    XCTAssertEqual(context["hasAttendeesOverflow"] as? Bool, false)
    XCTAssertEqual(context["attendeesOverflowCount"] as? Int, 0)
  }

  func testAttendeesTruncatedWhenExceedingLimit() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(attendees: 2)
    )
    let event = makeEvent(attendees: makeAttendees(count: 5))
    let context = ctx.buildContext(for: event)

    let attendees = context["attendees"] as? [[String: Any]]
    XCTAssertEqual(attendees?.count, 2)
    XCTAssertEqual(attendees?.first?["name"] as? String, "Person 0")
    XCTAssertEqual(attendees?.last?["name"] as? String, "Person 1")
  }

  func testAttendeesOverflowCountCorrect() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(attendees: 2)
    )
    let event = makeEvent(attendees: makeAttendees(count: 5))
    let context = ctx.buildContext(for: event)

    XCTAssertEqual(context["attendeesOverflowCount"] as? Int, 3)
  }

  func testHasAttendeesOverflowFalseWhenNotTruncated() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(attendees: 10)
    )
    let event = makeEvent(attendees: makeAttendees(count: 3))
    let context = ctx.buildContext(for: event)

    XCTAssertEqual(context["hasAttendeesOverflow"] as? Bool, false)
  }

  func testAttendeesTotalCountReflectsFullArray() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(attendees: 2)
    )
    let event = makeEvent(attendees: makeAttendees(count: 5))
    let context = ctx.buildContext(for: event)

    XCTAssertEqual(context["attendeesTotalCount"] as? Int, 5)
  }

  func testAttendeesZeroLimitMeansNoTruncation() {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(attendees: 0)
    )
    let event = makeEvent(attendees: makeAttendees(count: 5))
    let context = ctx.buildContext(for: event)

    let attendees = context["attendees"] as? [[String: Any]]
    XCTAssertEqual(attendees?.count, 5)
    XCTAssertEqual(context["hasAttendeesOverflow"] as? Bool, false)
  }

  func testAttendeesOverflowRendersInMustacheTemplate() throws {
    let ctx = EventTemplateContext(
      truncation: TruncationLimits(attendees: 2)
    )
    let event = makeEvent(attendees: makeAttendees(count: 5))
    let context = ctx.buildContext(for: event)

    let templateStr =
      "{{#attendees}}{{{name}}}\n{{/attendees}}"
      + "{{#hasAttendeesOverflow}}... and {{attendeesOverflowCount}} more{{/hasAttendeesOverflow}}"
    let template = try MustacheTemplate(string: templateStr)
    let result = template.render(context)
    XCTAssertTrue(result.contains("Person 0"))
    XCTAssertTrue(result.contains("Person 1"))
    XCTAssertFalse(result.contains("Person 2"))
    XCTAssertTrue(result.contains("... and 3 more"))
  }
}

// MARK: - Config Integration Tests

final class TruncationConfigTests: XCTestCase {
  func testUserConfigTruncationFields() {
    let config = UserConfig(truncateNotes: 50, truncateLocation: 30)
    XCTAssertEqual(config.truncateNotes, 50)
    XCTAssertEqual(config.truncateLocation, 30)
  }

  func testUserConfigTruncationDefaultsNil() {
    let config = UserConfig()
    XCTAssertNil(config.truncateNotes)
    XCTAssertNil(config.truncateLocation)
  }

  func testRuntimeOptionsResolveTruncation() throws {
    let config = UserConfig(
      truncateNotes: 50, truncateLocation: 30
    )
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    XCTAssertEqual(opts.truncation.notes, 50)
    XCTAssertEqual(opts.truncation.location, 30)
  }

  func testRuntimeOptionsDefaultTruncation() throws {
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)

    XCTAssertNil(opts.truncation.notes)
    XCTAssertNil(opts.truncation.location)
  }

  func testFormatterFactoryPassesTruncation() throws {
    let truncation = TruncationLimits(notes: 10, location: 8)
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: true, noColor: true,
      truncation: truncation
    )
    XCTAssertTrue(formatter is TemplateFormatter)
  }

  func testUserConfigMaxAttendeesField() {
    let config = UserConfig(maxAttendees: 10)
    XCTAssertEqual(config.maxAttendees, 10)
  }

  func testRuntimeOptionsResolveMaxAttendees() throws {
    let config = UserConfig(maxAttendees: 10)
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    XCTAssertEqual(opts.truncation.attendees, 10)
  }

  func testCLIOverridesConfigForMaxAttendees() throws {
    let config = UserConfig(maxAttendees: 10)
    let cli = CLIOptions(maxAttendees: 3)
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)

    XCTAssertEqual(opts.truncation.attendees, 3)
  }
}
