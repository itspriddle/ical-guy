import Foundation
import XCTest

@testable import ICalGuyKit

final class EventServiceTests: XCTestCase {
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

  // MARK: - Basic Query

  func testFetchEventsReturnsMatchingEvents() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Morning Meeting",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0)
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Morning Meeting")
    XCTAssertEqual(events[0].status, "confirmed")
  }

  func testFetchEventsReturnsEmptyForNoMatch() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Yesterday's Meeting",
        startDate: date(2024, 3, 14, 9, 0),
        endDate: date(2024, 3, 14, 10, 0)
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertTrue(events.isEmpty)
  }

  // MARK: - Multi-day Event Overlap

  func testMultiDayEventAppearsInMiddleOfSpan() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Conference",
        startDate: date(2024, 3, 14, 0, 0),
        endDate: date(2024, 3, 17, 0, 0),
        isAllDay: true
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Conference")
  }

  // MARK: - Date Range Boundaries

  func testEventEntirelyBeforeRangeIsExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Yesterday's Event",
        startDate: date(2024, 3, 14, 9, 0),
        endDate: date(2024, 3, 14, 10, 0)
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertTrue(events.isEmpty)
  }

  func testEventEntirelyAfterRangeIsExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Tomorrow's Event",
        startDate: date(2024, 3, 16, 9, 0),
        endDate: date(2024, 3, 16, 10, 0)
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertTrue(events.isEmpty)
  }

  func testEventOverlappingRangeStartIsIncluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Late Night Event",
        startDate: date(2024, 3, 14, 22, 0),
        endDate: date(2024, 3, 15, 2, 0)
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Late Night Event")
  }

  func testEventEndingExactlyAtRangeStartIsExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Ends At Midnight",
        startDate: date(2024, 3, 14, 23, 0),
        endDate: date(2024, 3, 15, 0, 0)
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertTrue(events.isEmpty)
  }

  func testEventStartingExactlyAtRangeEndIsExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Starts At End",
        startDate: date(2024, 3, 16, 0, 0),
        endDate: date(2024, 3, 16, 1, 0)
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 16, 0, 0)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertTrue(events.isEmpty)
  }

  // MARK: - Calendar Filtering

  func testIncludeCalendars() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Work Meeting",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        calendarTitle: "Work"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Personal Errand",
        startDate: date(2024, 3, 15, 11, 0),
        endDate: date(2024, 3, 15, 12, 0),
        calendarTitle: "Personal"
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      includeCalendars: ["Work"]
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Work Meeting")
  }

  func testExcludeCalendars() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Work Meeting",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        calendarTitle: "Work"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Personal Errand",
        startDate: date(2024, 3, 15, 11, 0),
        endDate: date(2024, 3, 15, 12, 0),
        calendarTitle: "Personal"
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      excludeCalendars: ["Personal"]
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Work Meeting")
  }

  func testCalendarFilteringIsCaseInsensitive() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Meeting",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        calendarTitle: "Work"
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      includeCalendars: ["work"]
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
  }

  // MARK: - All-day Filtering

  func testExcludeAllDay() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "All Day Event",
        startDate: date(2024, 3, 15, 0, 0),
        endDate: date(2024, 3, 16, 0, 0),
        isAllDay: true
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Timed Event",
        startDate: date(2024, 3, 15, 14, 0),
        endDate: date(2024, 3, 15, 15, 0)
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      excludeAllDay: true
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Timed Event")
  }

  // MARK: - Sorting

  func testEventsSortedByStartDate() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Afternoon",
        startDate: date(2024, 3, 15, 14, 0),
        endDate: date(2024, 3, 15, 15, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Morning",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0)
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events[0].title, "Morning")
    XCTAssertEqual(events[1].title, "Afternoon")
  }

  func testEventsSortedByTitleWhenSameStart() throws {
    let start = date(2024, 3, 15, 9, 0)
    let end = date(2024, 3, 15, 10, 0)

    store.mockEvents = [
      MockEventStore.sampleEvent(id: "e1", title: "Zebra", startDate: start, endDate: end),
      MockEventStore.sampleEvent(id: "e2", title: "Alpha", startDate: start, endDate: end),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events[0].title, "Alpha")
    XCTAssertEqual(events[1].title, "Zebra")
  }

  // MARK: - Limit

  func testLimit() throws {
    store.mockEvents = (1...5).map { i in
      MockEventStore.sampleEvent(
        id: "e\(i)", title: "Event \(i)",
        startDate: date(2024, 3, 15, 8 + i, 0),
        endDate: date(2024, 3, 15, 9 + i, 0)
      )
    }

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      limit: 3
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 3)
  }

  // MARK: - Calendars

  func testFetchCalendars() throws {
    store.mockCalendars = [
      MockEventStore.sampleCalendar(id: "c1", title: "Work"),
      MockEventStore.sampleCalendar(
        id: "c2", title: "Personal", type: "local", source: "On My Mac"),
    ]

    let calendars = try service.fetchCalendars()
    XCTAssertEqual(calendars.count, 2)
    XCTAssertEqual(calendars[0].title, "Work")
    XCTAssertEqual(calendars[1].title, "Personal")
  }

  // MARK: - Status Mapping

  func testStatusMapping() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "None",
        startDate: date(2024, 3, 15, 9, 0), endDate: date(2024, 3, 15, 10, 0), status: 0
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Confirmed",
        startDate: date(2024, 3, 15, 10, 0), endDate: date(2024, 3, 15, 11, 0), status: 1
      ),
      MockEventStore.sampleEvent(
        id: "e3", title: "Tentative",
        startDate: date(2024, 3, 15, 11, 0), endDate: date(2024, 3, 15, 12, 0), status: 2
      ),
      MockEventStore.sampleEvent(
        id: "e4", title: "Canceled",
        startDate: date(2024, 3, 15, 12, 0), endDate: date(2024, 3, 15, 13, 0), status: 3
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events[0].status, "none")
    XCTAssertEqual(events[1].status, "confirmed")
    XCTAssertEqual(events[2].status, "tentative")
    XCTAssertEqual(events[3].status, "canceled")
  }

  // MARK: - Meeting URL

  func testMeetingURLExtractedFromNotes() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Standup",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        notes: "Join: https://meet.google.com/abc-defg-hij"
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events[0].meetingUrl, "https://meet.google.com/abc-defg-hij")
  }

  func testMeetingURLNilWhenNoMatch() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Lunch",
        startDate: date(2024, 3, 15, 12, 0),
        endDate: date(2024, 3, 15, 13, 0),
        notes: "Bring your own lunch"
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertNil(events[0].meetingUrl)
  }

  // MARK: - Overlaps With

  func testOverlapsWithIncludesCurrentEvent() throws {
    // Event started 30min ago, ends in 30min
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "In Progress",
        startDate: date(2024, 3, 15, 9, 30),
        endDate: date(2024, 3, 15, 10, 30)
      )
    ]

    let now = date(2024, 3, 15, 10, 0)
    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      overlapsWith: now
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "In Progress")
  }

  func testOverlapsWithExcludesEndedEvent() throws {
    // Event ended 5 minutes ago
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Already Ended",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 9, 55)
      )
    ]

    let now = date(2024, 3, 15, 10, 0)
    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      overlapsWith: now
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertTrue(events.isEmpty)
  }

  func testOverlapsWithExcludesFutureEvent() throws {
    // Event starts in 5 minutes
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Starting Soon",
        startDate: date(2024, 3, 15, 10, 5),
        endDate: date(2024, 3, 15, 11, 0)
      )
    ]

    let now = date(2024, 3, 15, 10, 0)
    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      overlapsWith: now
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertTrue(events.isEmpty)
  }

  func testOverlapsWithIncludesAllDayEvent() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "All Day",
        startDate: date(2024, 3, 15, 0, 0),
        endDate: date(2024, 3, 16, 0, 0),
        isAllDay: true
      )
    ]

    let now = date(2024, 3, 15, 10, 0)
    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      overlapsWith: now
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "All Day")
  }

  func testOverlapsWithIncludesEventStartingExactlyAtNow() throws {
    // Event starts exactly at "now" — should be included (uses <=)
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Starting Now",
        startDate: date(2024, 3, 15, 10, 0),
        endDate: date(2024, 3, 15, 11, 0)
      )
    ]

    let now = date(2024, 3, 15, 10, 0)
    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      overlapsWith: now
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].title, "Starting Now")
  }

  func testOverlapsWithExcludesEventEndingExactlyAtNow() throws {
    // Event ends exactly at "now" — should be excluded (uses >)
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Just Ended",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0)
      )
    ]

    let now = date(2024, 3, 15, 10, 0)
    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59),
      overlapsWith: now
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertTrue(events.isEmpty)
  }

  // MARK: - Helpers

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
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

// MARK: - Event Detail Conversion Tests

final class EventServiceDetailTests: XCTestCase {
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

  func testAttendeeConversion() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Team Sync",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        attendees: [
          MockEventStore.sampleAttendee(
            name: "Alice", email: "alice@example.com",
            status: 2, role: 1, isCurrentUser: false
          ),
          MockEventStore.sampleAttendee(
            name: "Bob", email: "bob@example.com",
            status: 4, role: 2, isCurrentUser: true
          ),
        ],
        organizer: MockEventStore.sampleOrganizer(
          name: "Alice", email: "alice@example.com"
        )
      )
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    let event = events[0]

    XCTAssertEqual(event.attendees.count, 2)

    XCTAssertEqual(event.attendees[0].name, "Alice")
    XCTAssertEqual(event.attendees[0].email, "alice@example.com")
    XCTAssertEqual(event.attendees[0].status, .accepted)
    XCTAssertEqual(event.attendees[0].role, .required)
    XCTAssertFalse(event.attendees[0].isCurrentUser)

    XCTAssertEqual(event.attendees[1].name, "Bob")
    XCTAssertEqual(event.attendees[1].status, .tentative)
    XCTAssertEqual(event.attendees[1].role, .optional)
    XCTAssertTrue(event.attendees[1].isCurrentUser)

    XCTAssertEqual(event.organizer?.name, "Alice")
    XCTAssertEqual(event.organizer?.email, "alice@example.com")
  }

  func testAvailabilityMapping() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Busy",
        startDate: date(2024, 3, 15, 9, 0), endDate: date(2024, 3, 15, 10, 0),
        availability: 0
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Free",
        startDate: date(2024, 3, 15, 10, 0), endDate: date(2024, 3, 15, 11, 0),
        availability: 1
      ),
      MockEventStore.sampleEvent(
        id: "e3", title: "Tentative",
        startDate: date(2024, 3, 15, 11, 0), endDate: date(2024, 3, 15, 12, 0),
        availability: 2
      ),
      MockEventStore.sampleEvent(
        id: "e4", title: "Unavailable",
        startDate: date(2024, 3, 15, 12, 0), endDate: date(2024, 3, 15, 13, 0),
        availability: 3
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertEqual(events[0].availability, "busy")
    XCTAssertEqual(events[1].availability, "free")
    XCTAssertEqual(events[2].availability, "tentative")
    XCTAssertEqual(events[3].availability, "unavailable")
  }

  func testRecurrenceInfo() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Recurring",
        startDate: date(2024, 3, 15, 9, 0), endDate: date(2024, 3, 15, 10, 0),
        isRecurring: true, recurrenceDescription: "Every weekday"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "One-off",
        startDate: date(2024, 3, 15, 10, 0), endDate: date(2024, 3, 15, 11, 0)
      ),
    ]

    let options = EventServiceOptions(
      from: date(2024, 3, 15, 0, 0),
      to: date(2024, 3, 15, 23, 59)
    )

    let events = try service.fetchEvents(options: options)
    XCTAssertTrue(events[0].recurrence.isRecurring)
    XCTAssertEqual(events[0].recurrence.description, "Every weekday")
    XCTAssertFalse(events[1].recurrence.isRecurring)
    XCTAssertNil(events[1].recurrence.description)
  }

  // MARK: - Helpers

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
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
