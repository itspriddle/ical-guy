import Foundation
import XCTest

@testable import ICalGuyKit

final class EventGrouperTests: XCTestCase {
  private var grouper: EventGrouper!
  private var cal: Calendar!

  override func setUp() {
    super.setUp()
    cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/New_York")!
    grouper = EventGrouper(calendar: cal)
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

  private func makeReminder(
    id: String = "rem-1",
    title: String = "Task",
    listId: String = "list-1",
    listTitle: String = "Personal"
  ) -> Reminder {
    Reminder(
      id: id,
      title: title,
      list: ReminderListInfo(
        id: listId,
        title: listTitle,
        color: "#FF0000",
        source: "iCloud"
      )
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
        isAllDay: true),
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
        isAllDay: true),
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
        startDate: date(2024, 3, 15, 22), endDate: date(2024, 3, 16, 2)),
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
        startDate: date(2024, 3, 15, 22), endDate: date(2024, 3, 16)),
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
        isAllDay: true),
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

  // MARK: - Reminder List Grouping

  func testGroupRemindersByList() {
    let reminders = [
      makeReminder(id: "1", title: "Buy milk", listId: "list-1", listTitle: "Shopping"),
      makeReminder(id: "2", title: "Call dentist", listId: "list-2", listTitle: "Personal"),
      makeReminder(id: "3", title: "Buy eggs", listId: "list-1", listTitle: "Shopping"),
    ]

    let groups = grouper.groupRemindersByList(reminders)

    XCTAssertEqual(groups.count, 2)
    // Sorted by title: Personal < Shopping
    XCTAssertEqual(groups[0].list.title, "Personal")
    XCTAssertEqual(groups[0].reminders.count, 1)
    XCTAssertEqual(groups[1].list.title, "Shopping")
    XCTAssertEqual(groups[1].reminders.count, 2)
  }

  func testGroupRemindersByListEmpty() {
    let groups = grouper.groupRemindersByList([])
    XCTAssertTrue(groups.isEmpty)
  }
}
