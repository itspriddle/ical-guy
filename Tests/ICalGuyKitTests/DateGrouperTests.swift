import Foundation
import XCTest

@testable import ICalGuyKit

final class DateGrouperTests: XCTestCase {
  private var grouper: DateGrouper!
  private var cal: Calendar!

  override func setUp() {
    super.setUp()
    cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/New_York")!
    grouper = DateGrouper(calendar: cal)
  }

  // MARK: - Helpers

  private func date(
    _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0
  ) -> Date {
    cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
  }

  private func makeEvent(
    id: String = "evt-1",
    title: String = "Meeting",
    startDate: Date,
    endDate: Date,
    isAllDay: Bool = false,
    calendarId: String = "cal-1",
    calendarTitle: String = "Work",
    calendarColor: String = "#1BADF8"
  ) -> CalendarEvent {
    CalendarEvent(
      id: id,
      title: title,
      startDate: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      location: nil,
      notes: nil,
      url: nil,
      calendar: CalendarInfo(
        id: calendarId,
        title: calendarTitle,
        type: "calDAV",
        source: "iCloud",
        color: calendarColor
      ),
      status: "confirmed"
    )
  }

  // MARK: - Date Grouping

  func testGroupByDateSingleDay() {
    let events = [
      makeEvent(
        id: "1", title: "Morning", startDate: date(2024, 3, 15, 9), endDate: date(2024, 3, 15, 10)),
      makeEvent(
        id: "2", title: "Afternoon", startDate: date(2024, 3, 15, 14),
        endDate: date(2024, 3, 15, 15)),
    ]

    let groups = grouper.groupByDate(events)

    XCTAssertEqual(groups.count, 1)
    XCTAssertEqual(groups[0].date, "2024-03-15")
    XCTAssertEqual(groups[0].events.count, 2)
  }

  func testGroupByDateMultiDay() {
    let events = [
      makeEvent(
        id: "1", title: "Day 1", startDate: date(2024, 3, 15, 9), endDate: date(2024, 3, 15, 10)),
      makeEvent(
        id: "2", title: "Day 2", startDate: date(2024, 3, 16, 9), endDate: date(2024, 3, 16, 10)),
      makeEvent(
        id: "3", title: "Day 3", startDate: date(2024, 3, 17, 9), endDate: date(2024, 3, 17, 10)),
    ]

    let groups = grouper.groupByDate(events)

    XCTAssertEqual(groups.count, 3)
    XCTAssertEqual(groups[0].date, "2024-03-15")
    XCTAssertEqual(groups[1].date, "2024-03-16")
    XCTAssertEqual(groups[2].date, "2024-03-17")
  }

  func testGroupByDateShowEmptyDates() {
    let events = [
      makeEvent(
        id: "1", title: "Day 1", startDate: date(2024, 3, 15, 9), endDate: date(2024, 3, 15, 10)),
      makeEvent(
        id: "2", title: "Day 3", startDate: date(2024, 3, 17, 9), endDate: date(2024, 3, 17, 10)),
    ]

    let groups = grouper.groupByDate(
      events,
      from: date(2024, 3, 15),
      to: date(2024, 3, 17),
      showEmptyDates: true
    )

    XCTAssertEqual(groups.count, 3)
    XCTAssertEqual(groups[0].date, "2024-03-15")
    XCTAssertEqual(groups[0].events.count, 1)
    XCTAssertEqual(groups[1].date, "2024-03-16")
    XCTAssertEqual(groups[1].events.count, 0)
    XCTAssertEqual(groups[2].date, "2024-03-17")
    XCTAssertEqual(groups[2].events.count, 1)
  }

  func testGroupByDateEmpty() {
    let groups = grouper.groupByDate([])
    XCTAssertTrue(groups.isEmpty)
  }

  func testGroupByDateShowEmptyDatesNoEvents() {
    let groups = grouper.groupByDate(
      [],
      from: date(2024, 3, 15),
      to: date(2024, 3, 17),
      showEmptyDates: true
    )

    XCTAssertEqual(groups.count, 3)
    XCTAssertTrue(groups.allSatisfy { $0.events.isEmpty })
  }

  // MARK: - Multi-day Event Spanning

  func testMultiDayAllDayEventSpansAllDates() {
    // 3-day all-day event: Mar 15-17 (EventKit end = Mar 18 00:00)
    let events = [
      makeEvent(
        id: "1", title: "Conference",
        startDate: date(2024, 3, 15), endDate: date(2024, 3, 18),
        isAllDay: true)
    ]

    let groups = grouper.groupByDate(events)

    XCTAssertEqual(groups.count, 3)
    XCTAssertEqual(groups[0].date, "2024-03-15")
    XCTAssertEqual(groups[0].events.count, 1)
    XCTAssertEqual(groups[0].events[0].title, "Conference")
    XCTAssertEqual(groups[1].date, "2024-03-16")
    XCTAssertEqual(groups[1].events.count, 1)
    XCTAssertEqual(groups[1].events[0].title, "Conference")
    XCTAssertEqual(groups[2].date, "2024-03-17")
    XCTAssertEqual(groups[2].events.count, 1)
    XCTAssertEqual(groups[2].events[0].title, "Conference")
  }

  func testSingleDayAllDayEventStaysInOneGroup() {
    // 1-day all-day event: Mar 15 (EventKit end = Mar 16 00:00)
    let events = [
      makeEvent(
        id: "1", title: "Holiday",
        startDate: date(2024, 3, 15), endDate: date(2024, 3, 16),
        isAllDay: true)
    ]

    let groups = grouper.groupByDate(events)

    XCTAssertEqual(groups.count, 1)
    XCTAssertEqual(groups[0].date, "2024-03-15")
    XCTAssertEqual(groups[0].events.count, 1)
  }

  func testTimedOvernightEventSpansTwoDays() {
    // Timed event from 10pm Mar 15 to 2am Mar 16
    let events = [
      makeEvent(
        id: "1", title: "Late Night",
        startDate: date(2024, 3, 15, 22), endDate: date(2024, 3, 16, 2))
    ]

    let groups = grouper.groupByDate(events)

    XCTAssertEqual(groups.count, 2)
    XCTAssertEqual(groups[0].date, "2024-03-15")
    XCTAssertEqual(groups[0].events.count, 1)
    XCTAssertEqual(groups[1].date, "2024-03-16")
    XCTAssertEqual(groups[1].events.count, 1)
  }

  func testTimedEventEndingAtMidnightStaysInOneGroup() {
    // Timed event from 10pm to midnight — should not spill into next day
    let events = [
      makeEvent(
        id: "1", title: "Evening Event",
        startDate: date(2024, 3, 15, 22), endDate: date(2024, 3, 16))
    ]

    let groups = grouper.groupByDate(events)

    XCTAssertEqual(groups.count, 1)
    XCTAssertEqual(groups[0].date, "2024-03-15")
    XCTAssertEqual(groups[0].events.count, 1)
  }

  func testMultiDayEventWithShowEmptyDates() {
    // 3-day all-day event spanning the full range, plus an empty day
    let events = [
      makeEvent(
        id: "1", title: "Conference",
        startDate: date(2024, 3, 15), endDate: date(2024, 3, 18),
        isAllDay: true)
    ]

    let groups = grouper.groupByDate(
      events,
      from: date(2024, 3, 14),
      to: date(2024, 3, 18),
      showEmptyDates: true
    )

    XCTAssertEqual(groups.count, 5)
    XCTAssertEqual(groups[0].date, "2024-03-14")
    XCTAssertEqual(groups[0].events.count, 0)
    XCTAssertEqual(groups[1].date, "2024-03-15")
    XCTAssertEqual(groups[1].events.count, 1)
    XCTAssertEqual(groups[2].date, "2024-03-16")
    XCTAssertEqual(groups[2].events.count, 1)
    XCTAssertEqual(groups[3].date, "2024-03-17")
    XCTAssertEqual(groups[3].events.count, 1)
    XCTAssertEqual(groups[4].date, "2024-03-18")
    XCTAssertEqual(groups[4].events.count, 0)
  }

  func testMultiDaySpanningWithOtherSingleDayEvents() {
    // A spanning event plus regular single-day events
    let events = [
      makeEvent(
        id: "1", title: "Conference",
        startDate: date(2024, 3, 15), endDate: date(2024, 3, 18),
        isAllDay: true),
      makeEvent(
        id: "2", title: "Lunch",
        startDate: date(2024, 3, 16, 12), endDate: date(2024, 3, 16, 13)),
    ]

    let groups = grouper.groupByDate(events)

    XCTAssertEqual(groups.count, 3)

    let mar15 = groups.first { $0.date == "2024-03-15" }!
    XCTAssertEqual(mar15.events.count, 1)
    XCTAssertEqual(mar15.events[0].title, "Conference")

    let mar16 = groups.first { $0.date == "2024-03-16" }!
    XCTAssertEqual(mar16.events.count, 2)
    XCTAssertTrue(mar16.events.contains { $0.title == "Conference" })
    XCTAssertTrue(mar16.events.contains { $0.title == "Lunch" })

    let mar17 = groups.first { $0.date == "2024-03-17" }!
    XCTAssertEqual(mar17.events.count, 1)
    XCTAssertEqual(mar17.events[0].title, "Conference")
  }

  // MARK: - Day Bucket Clipping

  func testMultiDayEventClippedToRangeStart() {
    // 3-day event starting Mar 14, but query from Mar 15
    let events = [
      makeEvent(
        id: "1", title: "Conference",
        startDate: date(2024, 3, 14), endDate: date(2024, 3, 17),
        isAllDay: true)
    ]

    let groups = grouper.groupByDate(events, from: date(2024, 3, 15), to: date(2024, 3, 17))

    // Should not have a Mar 14 bucket
    XCTAssertFalse(groups.contains { $0.date == "2024-03-14" })
    XCTAssertTrue(groups.contains { $0.date == "2024-03-15" })
    XCTAssertTrue(groups.contains { $0.date == "2024-03-16" })
  }

  func testMultiDayEventClippedToRangeEnd() {
    // Event spanning Mar 15-18, but query to Mar 16
    let events = [
      makeEvent(
        id: "1", title: "Long Event",
        startDate: date(2024, 3, 15), endDate: date(2024, 3, 19),
        isAllDay: true)
    ]

    let groups = grouper.groupByDate(events, from: date(2024, 3, 15), to: date(2024, 3, 16))

    XCTAssertEqual(groups.count, 2)
    XCTAssertEqual(groups[0].date, "2024-03-15")
    XCTAssertEqual(groups[1].date, "2024-03-16")
    XCTAssertFalse(groups.contains { $0.date == "2024-03-17" })
    XCTAssertFalse(groups.contains { $0.date == "2024-03-18" })
  }

  func testSingleDayEventBeforeRangeExcludedFromGrouping() {
    // Event on Mar 14, grouped with from=Mar 15
    let events = [
      makeEvent(
        id: "1", title: "Old Event",
        startDate: date(2024, 3, 14, 9), endDate: date(2024, 3, 14, 10))
    ]

    let groups = grouper.groupByDate(events, from: date(2024, 3, 15))

    XCTAssertTrue(groups.isEmpty)
  }

  func testGroupByDateClipsWithFromToAndShowEmptyDatesFalse() {
    // Multi-day event that extends beyond query range, showEmptyDates=false (default)
    let events = [
      makeEvent(
        id: "1", title: "Conference",
        startDate: date(2024, 3, 14), endDate: date(2024, 3, 18),
        isAllDay: true),
      makeEvent(
        id: "2", title: "Meeting",
        startDate: date(2024, 3, 15, 10), endDate: date(2024, 3, 15, 11)),
    ]

    let groups = grouper.groupByDate(
      events, from: date(2024, 3, 15), to: date(2024, 3, 16))

    // Only Mar 15 and Mar 16 buckets, no Mar 14 or Mar 17
    XCTAssertEqual(groups.count, 2)
    XCTAssertEqual(groups[0].date, "2024-03-15")
    XCTAssertEqual(groups[0].events.count, 2)  // Conference + Meeting
    XCTAssertEqual(groups[1].date, "2024-03-16")
    XCTAssertEqual(groups[1].events.count, 1)  // Conference only
  }
}
