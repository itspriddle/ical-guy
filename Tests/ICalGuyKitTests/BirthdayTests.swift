import Foundation
import XCTest

@testable import ICalGuyKit

final class BirthdayTests: XCTestCase {
  private var store: MockEventStore!
  private var service: EventService!
  private var cal: Calendar!

  override func setUp() {
    super.setUp()
    store = MockEventStore()
    service = EventService(store: store)
    cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/New_York")!
  }

  // MARK: - Filtering

  func testFetchBirthdaysReturnsBirthdayCalendarOnly() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "b1", title: "John Smith",
        startDate: date(2026, 2, 16, 0, 0),
        endDate: date(2026, 2, 17, 0, 0),
        isAllDay: true,
        calendarType: "birthday"
      ),
      MockEventStore.sampleEvent(
        id: "e1", title: "Work Meeting",
        startDate: date(2026, 2, 16, 9, 0),
        endDate: date(2026, 2, 16, 10, 0),
        calendarType: "calDAV"
      ),
    ]

    let birthdays = try service.fetchBirthdays(
      from: date(2026, 2, 16, 0, 0),
      to: date(2026, 2, 17, 0, 0)
    )

    XCTAssertEqual(birthdays.count, 1)
    XCTAssertEqual(birthdays[0].name, "John Smith")
  }

  func testNonBirthdayEventsFilteredOut() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Meeting",
        startDate: date(2026, 2, 16, 9, 0),
        endDate: date(2026, 2, 16, 10, 0),
        calendarType: "calDAV"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Holiday",
        startDate: date(2026, 2, 16, 0, 0),
        endDate: date(2026, 2, 17, 0, 0),
        isAllDay: true,
        calendarType: "subscription"
      ),
    ]

    let birthdays = try service.fetchBirthdays(
      from: date(2026, 2, 16, 0, 0),
      to: date(2026, 2, 17, 0, 0)
    )

    XCTAssertTrue(birthdays.isEmpty)
  }

  // MARK: - Sorting

  func testSortedByDateThenName() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "b1", title: "Zara Jones",
        startDate: date(2026, 2, 16, 0, 0),
        endDate: date(2026, 2, 17, 0, 0),
        isAllDay: true,
        calendarType: "birthday"
      ),
      MockEventStore.sampleEvent(
        id: "b2", title: "Alice Smith",
        startDate: date(2026, 2, 16, 0, 0),
        endDate: date(2026, 2, 17, 0, 0),
        isAllDay: true,
        calendarType: "birthday"
      ),
      MockEventStore.sampleEvent(
        id: "b3", title: "Bob Lee",
        startDate: date(2026, 2, 18, 0, 0),
        endDate: date(2026, 2, 19, 0, 0),
        isAllDay: true,
        calendarType: "birthday"
      ),
    ]

    let birthdays = try service.fetchBirthdays(
      from: date(2026, 2, 16, 0, 0),
      to: date(2026, 2, 19, 0, 0)
    )

    XCTAssertEqual(birthdays.count, 3)
    XCTAssertEqual(birthdays[0].name, "Alice Smith")
    XCTAssertEqual(birthdays[1].name, "Zara Jones")
    XCTAssertEqual(birthdays[2].name, "Bob Lee")
  }

  // MARK: - Limit

  func testLimitApplied() throws {
    store.mockEvents = (1...5).map { i in
      MockEventStore.sampleEvent(
        id: "b\(i)", title: "Person \(i)",
        startDate: date(2026, 2, 15 + i, 0, 0),
        endDate: date(2026, 2, 16 + i, 0, 0),
        isAllDay: true,
        calendarType: "birthday"
      )
    }

    let birthdays = try service.fetchBirthdays(
      from: date(2026, 2, 16, 0, 0),
      to: date(2026, 2, 21, 0, 0),
      limit: 2
    )

    XCTAssertEqual(birthdays.count, 2)
  }

  // MARK: - Empty Results

  func testEmptyWhenNoBirthdayEvents() throws {
    store.mockEvents = []

    let birthdays = try service.fetchBirthdays(
      from: date(2026, 2, 16, 0, 0),
      to: date(2026, 2, 17, 0, 0)
    )

    XCTAssertTrue(birthdays.isEmpty)
  }

  // MARK: - Field Mapping

  func testBirthdayFieldsMappedCorrectly() throws {
    let startDate = date(2026, 2, 16, 0, 0)
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "b1", title: "Jane Doe",
        startDate: startDate,
        endDate: date(2026, 2, 17, 0, 0),
        isAllDay: true,
        calendarId: "bday-cal",
        calendarTitle: "Birthdays",
        calendarType: "birthday",
        calendarSource: "Contacts",
        calendarColor: "#FF0000"
      )
    ]

    let birthdays = try service.fetchBirthdays(
      from: date(2026, 2, 16, 0, 0),
      to: date(2026, 2, 17, 0, 0)
    )

    XCTAssertEqual(birthdays.count, 1)
    let birthday = birthdays[0]
    XCTAssertEqual(birthday.name, "Jane Doe")
    XCTAssertEqual(birthday.date, startDate)
    XCTAssertEqual(birthday.calendar.id, "bday-cal")
    XCTAssertEqual(birthday.calendar.title, "Birthdays")
    XCTAssertEqual(birthday.calendar.type, "birthday")
    XCTAssertEqual(birthday.calendar.source, "Contacts")
    XCTAssertEqual(birthday.calendar.color, "#FF0000")
  }

  // MARK: - Helpers

  private func date(
    _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int
  ) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = 0
    components.timeZone = TimeZone(identifier: "America/New_York")
    return cal.date(from: components)!
  }
}
