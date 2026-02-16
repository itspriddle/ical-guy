import Foundation
import XCTest

@testable import ICalGuyKit

final class EventServiceCalendarTypeTests: XCTestCase {
  private var store: MockEventStore!
  private var service: EventService!
  private var calendar: Calendar!

  override func setUp() {
    super.setUp()
    store = MockEventStore()
    service = EventService(store: store)
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
  }

  func testIncludeCalendarTypes() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Work Sync",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        calendarType: "calDAV", calendarSource: "iCloud"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Local Reminder",
        startDate: date(2024, 3, 15, 11, 0),
        endDate: date(2024, 3, 15, 12, 0),
        calendarType: "local", calendarSource: "On My Mac"
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      includeCalendarTypes: ["local"]
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Local Reminder")
  }

  func testExcludeCalendarTypes() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Work Sync",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        calendarType: "calDAV", calendarSource: "iCloud"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Newsletter",
        startDate: date(2024, 3, 15, 11, 0),
        endDate: date(2024, 3, 15, 12, 0),
        calendarType: "subscription", calendarSource: "Other"
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      excludeCalendarTypes: ["subscription"]
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Work Sync")
  }

  func testCalendarTypeFilteringIsCaseInsensitive() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Meeting",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        calendarType: "calDAV", calendarSource: "iCloud"
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      includeCalendarTypes: ["CALDAV"]
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
  }

  func testICloudTypeAlias() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "iCloud Event",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        calendarType: "calDAV", calendarSource: "iCloud"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Google Event",
        startDate: date(2024, 3, 15, 11, 0),
        endDate: date(2024, 3, 15, 12, 0),
        calendarType: "calDAV", calendarSource: "Google"
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      includeCalendarTypes: ["icloud"]
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "iCloud Event")
  }

  func testCombinedNameAndTypeFilters() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Work iCloud",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        calendarTitle: "Work",
        calendarType: "calDAV", calendarSource: "iCloud"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Personal iCloud",
        startDate: date(2024, 3, 15, 11, 0),
        endDate: date(2024, 3, 15, 12, 0),
        calendarTitle: "Personal",
        calendarType: "calDAV", calendarSource: "iCloud"
      ),
      MockEventStore.sampleEvent(
        id: "e3", title: "Work Local",
        startDate: date(2024, 3, 15, 13, 0),
        endDate: date(2024, 3, 15, 14, 0),
        calendarTitle: "Work",
        calendarType: "local", calendarSource: "On My Mac"
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      includeCalendars: ["Work"],
      includeCalendarTypes: ["calDAV"]
    )

    // Both filters apply: must be "Work" calendar AND calDAV type
    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Work iCloud")
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
    return calendar.date(from: components)!
  }
}
