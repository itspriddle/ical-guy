import Foundation
import XCTest

@testable import ICalGuyKit

final class CalendarGrouperTests: XCTestCase {
  private var grouper: CalendarGrouper!
  private var cal: Calendar!

  override func setUp() {
    super.setUp()
    cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/New_York")!
    grouper = CalendarGrouper()
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

  // MARK: - Calendar Grouping

  func testGroupByCalendar() {
    let events = [
      makeEvent(
        id: "1", title: "Work Event",
        startDate: date(2024, 3, 15, 9), endDate: date(2024, 3, 15, 10),
        calendarId: "cal-1", calendarTitle: "Work"
      ),
      makeEvent(
        id: "2", title: "Personal Event",
        startDate: date(2024, 3, 15, 11), endDate: date(2024, 3, 15, 12),
        calendarId: "cal-2", calendarTitle: "Personal"
      ),
      makeEvent(
        id: "3", title: "Another Work Event",
        startDate: date(2024, 3, 15, 14), endDate: date(2024, 3, 15, 15),
        calendarId: "cal-1", calendarTitle: "Work"
      ),
    ]

    let groups = grouper.groupByCalendar(events)

    XCTAssertEqual(groups.count, 2)
    // Sorted by title: Personal < Work
    XCTAssertEqual(groups[0].calendar.title, "Personal")
    XCTAssertEqual(groups[0].events.count, 1)
    XCTAssertEqual(groups[1].calendar.title, "Work")
    XCTAssertEqual(groups[1].events.count, 2)
  }

  func testGroupByCalendarSortedByStartDate() {
    let events = [
      makeEvent(
        id: "1", title: "Late",
        startDate: date(2024, 3, 15, 14), endDate: date(2024, 3, 15, 15),
        calendarId: "cal-1", calendarTitle: "Work"
      ),
      makeEvent(
        id: "2", title: "Early",
        startDate: date(2024, 3, 15, 9), endDate: date(2024, 3, 15, 10),
        calendarId: "cal-1", calendarTitle: "Work"
      ),
    ]

    let groups = grouper.groupByCalendar(events)

    XCTAssertEqual(groups.count, 1)
    XCTAssertEqual(groups[0].events[0].title, "Early")
    XCTAssertEqual(groups[0].events[1].title, "Late")
  }

  func testGroupByCalendarEmpty() {
    let groups = grouper.groupByCalendar([])
    XCTAssertTrue(groups.isEmpty)
  }
}
