import Foundation
import Mustache
import XCTest

@testable import ICalGuyKit

// MARK: - formatRelativeTime Unit Tests

final class RelativeTimeFormattingTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_710_500_400)  // fixed reference

  func testNow() {
    // Exactly the same time
    let result = EventTemplateContext.formatRelativeTime(from: now, to: now)
    XCTAssertEqual(result, "now")
  }

  func testWithinOneMinuteFuture() {
    let target = now.addingTimeInterval(30)  // 30 seconds
    XCTAssertEqual(EventTemplateContext.formatRelativeTime(from: now, to: target), "now")
  }

  func testWithinOneMinutePast() {
    let target = now.addingTimeInterval(-45)  // 45 seconds ago
    XCTAssertEqual(EventTemplateContext.formatRelativeTime(from: now, to: target), "now")
  }

  func testOneMinuteFuture() {
    let target = now.addingTimeInterval(60)
    XCTAssertEqual(EventTemplateContext.formatRelativeTime(from: now, to: target), "in 1 minute")
  }

  func testMinutesFuture() {
    let target = now.addingTimeInterval(30 * 60)  // 30 minutes
    XCTAssertEqual(EventTemplateContext.formatRelativeTime(from: now, to: target), "in 30 minutes")
  }

  func testMinutesPast() {
    let target = now.addingTimeInterval(-15 * 60)  // 15 minutes ago
    XCTAssertEqual(
      EventTemplateContext.formatRelativeTime(from: now, to: target), "15 minutes ago")
  }

  func testOneHourFuture() {
    let target = now.addingTimeInterval(3600)
    XCTAssertEqual(EventTemplateContext.formatRelativeTime(from: now, to: target), "in 1 hour")
  }

  func testHoursAndMinutesFuture() {
    let target = now.addingTimeInterval(2 * 3600 + 30 * 60)  // 2h30m
    XCTAssertEqual(
      EventTemplateContext.formatRelativeTime(from: now, to: target),
      "in 2 hours 30 minutes"
    )
  }

  func testHoursAndMinutesPast() {
    let target = now.addingTimeInterval(-(1 * 3600 + 15 * 60))  // 1h15m ago
    XCTAssertEqual(
      EventTemplateContext.formatRelativeTime(from: now, to: target),
      "1 hour 15 minutes ago"
    )
  }

  func testExactHoursPast() {
    let target = now.addingTimeInterval(-3 * 3600)  // 3 hours ago
    XCTAssertEqual(
      EventTemplateContext.formatRelativeTime(from: now, to: target), "3 hours ago")
  }

  func testOneDayFuture() {
    let target = now.addingTimeInterval(24 * 3600)
    XCTAssertEqual(EventTemplateContext.formatRelativeTime(from: now, to: target), "in 1 day")
  }

  func testMultipleDaysFuture() {
    let target = now.addingTimeInterval(3 * 24 * 3600)
    XCTAssertEqual(EventTemplateContext.formatRelativeTime(from: now, to: target), "in 3 days")
  }

  func testMultipleDaysPast() {
    let target = now.addingTimeInterval(-7 * 24 * 3600)
    XCTAssertEqual(EventTemplateContext.formatRelativeTime(from: now, to: target), "7 days ago")
  }

  func testSingularMinute() {
    let target = now.addingTimeInterval(-60)
    XCTAssertEqual(EventTemplateContext.formatRelativeTime(from: now, to: target), "1 minute ago")
  }

  func testHourWithOneMinute() {
    let target = now.addingTimeInterval(3600 + 60)  // 1h1m
    XCTAssertEqual(
      EventTemplateContext.formatRelativeTime(from: now, to: target),
      "in 1 hour 1 minute"
    )
  }
}

// MARK: - Context Integration Tests

final class RelativeDateContextTests: XCTestCase {
  private let testCalendar = CalendarInfo(
    id: "cal-1", title: "Work", type: "calDAV", source: "iCloud", color: "#1BADF8"
  )

  func testRelativeFieldsInContext() {
    let eventStart = Date(timeIntervalSince1970: 1_710_500_400)
    let eventEnd = Date(timeIntervalSince1970: 1_710_502_200)  // 30 min later
    let refDate = eventStart.addingTimeInterval(-1800)  // 30 min before start

    let event = CalendarEvent(
      id: "evt-1", title: "Test",
      startDate: eventStart, endDate: eventEnd,
      isAllDay: false, location: nil, notes: nil, url: nil,
      calendar: testCalendar, status: "confirmed"
    )

    let builder = EventTemplateContext(referenceDate: { refDate })
    let ctx = builder.buildContext(for: event)

    XCTAssertEqual(ctx["relativeStart"] as? String, "in 30 minutes")
    XCTAssertEqual(ctx["relativeEnd"] as? String, "in 1 hour")
  }

  func testRelativeFieldsForAllDayEvent() {
    let event = CalendarEvent(
      id: "evt-2", title: "Holiday",
      startDate: Date(timeIntervalSince1970: 1_710_460_800),
      endDate: Date(timeIntervalSince1970: 1_710_547_200),
      isAllDay: true, location: nil, notes: nil, url: nil,
      calendar: testCalendar, status: "confirmed"
    )

    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: event)

    XCTAssertEqual(ctx["relativeStart"] as? String, "all day")
    XCTAssertEqual(ctx["relativeEnd"] as? String, "all day")
  }

  func testRelativeFieldsForPastEvent() {
    let eventStart = Date(timeIntervalSince1970: 1_710_500_400)
    let eventEnd = Date(timeIntervalSince1970: 1_710_502_200)
    let refDate = eventEnd.addingTimeInterval(3600)  // 1 hour after end

    let event = CalendarEvent(
      id: "evt-3", title: "Past Event",
      startDate: eventStart, endDate: eventEnd,
      isAllDay: false, location: nil, notes: nil, url: nil,
      calendar: testCalendar, status: "confirmed"
    )

    let builder = EventTemplateContext(referenceDate: { refDate })
    let ctx = builder.buildContext(for: event)

    XCTAssertEqual(ctx["relativeStart"] as? String, "1 hour 30 minutes ago")
    XCTAssertEqual(ctx["relativeEnd"] as? String, "1 hour ago")
  }

  func testRelativeFieldsForOngoingEvent() {
    let eventStart = Date(timeIntervalSince1970: 1_710_500_400)
    let eventEnd = Date(timeIntervalSince1970: 1_710_502_200)
    let refDate = eventStart.addingTimeInterval(900)  // 15 min into event

    let event = CalendarEvent(
      id: "evt-4", title: "Ongoing",
      startDate: eventStart, endDate: eventEnd,
      isAllDay: false, location: nil, notes: nil, url: nil,
      calendar: testCalendar, status: "confirmed"
    )

    let builder = EventTemplateContext(referenceDate: { refDate })
    let ctx = builder.buildContext(for: event)

    XCTAssertEqual(ctx["relativeStart"] as? String, "15 minutes ago")
    XCTAssertEqual(ctx["relativeEnd"] as? String, "in 15 minutes")
  }

  func testRelativeFieldsRenderInTemplate() throws {
    let eventStart = Date(timeIntervalSince1970: 1_710_500_400)
    let eventEnd = Date(timeIntervalSince1970: 1_710_502_200)
    let refDate = eventStart.addingTimeInterval(-600)  // 10 min before start

    let event = CalendarEvent(
      id: "evt-5", title: "Meeting",
      startDate: eventStart, endDate: eventEnd,
      isAllDay: false, location: nil, notes: nil, url: nil,
      calendar: testCalendar, status: "confirmed"
    )

    let builder = EventTemplateContext(referenceDate: { refDate })
    let ctx = builder.buildContext(for: event)

    let template = try MustacheTemplate(
      string: "{{title}} starts {{relativeStart}}, ends {{relativeEnd}}"
    )
    let result = template.render(ctx)
    XCTAssertEqual(result, "Meeting starts in 10 minutes, ends in 40 minutes")
  }
}
