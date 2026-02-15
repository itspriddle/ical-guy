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
            )
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
            )
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
            )
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
            )
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
            MockEventStore.sampleEvent(id: "e2", title: "Alpha", startDate: start, endDate: end)
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
            MockEventStore.sampleCalendar(id: "c2", title: "Personal", type: "local", source: "On My Mac")
        ]

        let calendars = try service.fetchCalendars()
        XCTAssertEqual(calendars.count, 2)
        XCTAssertEqual(calendars[0].title, "Work")
        XCTAssertEqual(calendars[1].title, "Personal")
    }

    // MARK: - Status Mapping

    func testStatusMapping() throws {
        store.mockEvents = [
            MockEventStore.sampleEvent(id: "e1", title: "None", startDate: date(2024, 3, 15, 9, 0), endDate: date(2024, 3, 15, 10, 0), status: 0),
            MockEventStore.sampleEvent(id: "e2", title: "Confirmed", startDate: date(2024, 3, 15, 10, 0), endDate: date(2024, 3, 15, 11, 0), status: 1),
            MockEventStore.sampleEvent(id: "e3", title: "Tentative", startDate: date(2024, 3, 15, 11, 0), endDate: date(2024, 3, 15, 12, 0), status: 2),
            MockEventStore.sampleEvent(id: "e4", title: "Canceled", startDate: date(2024, 3, 15, 12, 0), endDate: date(2024, 3, 15, 13, 0), status: 3)
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
