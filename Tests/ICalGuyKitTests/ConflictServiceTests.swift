import Foundation
import XCTest

@testable import ICalGuyKit

final class ConflictServiceTests: XCTestCase {
  private var store: MockEventStore!
  private var service: ConflictService!
  private var cal: Calendar!

  override func setUp() {
    super.setUp()
    store = MockEventStore()
    service = ConflictService(store: store)
    cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/New_York")!
  }

  // MARK: - Basic Conflict Detection

  func testNoEventsNoConflicts() throws {
    store.mockEvents = []
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 0)
    XCTAssertTrue(result.groups.isEmpty)
  }

  func testSingleEventNoConflict() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Solo Meeting",
        startDate: date(9, 0), endDate: date(10, 0)
      )
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 0)
  }

  func testTwoOverlappingEventsOneConflict() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Team Standup",
        startDate: date(10, 0), endDate: date(11, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "1:1 with Alice",
        startDate: date(10, 30), endDate: date(11, 30)
      ),
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 1)
    XCTAssertEqual(result.groups[0].events.count, 2)
    XCTAssertEqual(result.groups[0].windowStart, date(10, 0))
    XCTAssertEqual(result.groups[0].windowEnd, date(11, 30))
  }

  func testAdjacentEventsNoConflict() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Meeting A",
        startDate: date(9, 0), endDate: date(10, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Meeting B",
        startDate: date(10, 0), endDate: date(11, 0)
      ),
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 0)
  }

  func testThreeEventCluster() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "A",
        startDate: date(9, 0), endDate: date(10, 30)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "B",
        startDate: date(10, 0), endDate: date(11, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e3", title: "C",
        startDate: date(10, 15), endDate: date(11, 15)
      ),
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 1)
    XCTAssertEqual(result.groups[0].events.count, 3)
  }

  func testTwoSeparateConflictGroups() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Morning A",
        startDate: date(9, 0), endDate: date(10, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Morning B",
        startDate: date(9, 30), endDate: date(10, 30)
      ),
      MockEventStore.sampleEvent(
        id: "e3", title: "Afternoon A",
        startDate: date(14, 0), endDate: date(15, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e4", title: "Afternoon B",
        startDate: date(14, 30), endDate: date(15, 30)
      ),
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 2)
    XCTAssertEqual(result.groups[0].events.count, 2)
    XCTAssertEqual(result.groups[1].events.count, 2)
  }

  // MARK: - Filtering

  func testCanceledEventsExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Active",
        startDate: date(10, 0), endDate: date(11, 0), status: 1
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Canceled",
        startDate: date(10, 30), endDate: date(11, 30), status: 3
      ),
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 0)
  }

  func testFreeAvailabilityExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Busy Meeting",
        startDate: date(10, 0), endDate: date(11, 0), availability: 0
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Show As Free",
        startDate: date(10, 30), endDate: date(11, 30), availability: 1
      ),
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 0)
  }

  func testDeclinedEventsExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Accepted Meeting",
        startDate: date(10, 0), endDate: date(11, 0),
        attendees: [
          MockEventStore.sampleAttendee(
            name: "Me", status: 2, isCurrentUser: true
          )
        ]
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Declined Meeting",
        startDate: date(10, 30), endDate: date(11, 30),
        attendees: [
          MockEventStore.sampleAttendee(
            name: "Me", status: 3, isCurrentUser: true
          )
        ]
      ),
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 0)
  }

  func testAllDayEventsExcludedByDefault() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "All Day",
        startDate: date(0, 0), endDate: date(23, 59), isAllDay: true
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Timed",
        startDate: date(10, 0), endDate: date(11, 0)
      ),
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 0)
  }

  func testAllDayEventsIncludedWhenFlagged() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "All Day",
        startDate: date(0, 0), endDate: date(23, 59), isAllDay: true
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Timed",
        startDate: date(10, 0), endDate: date(11, 0)
      ),
    ]
    let options = ConflictServiceOptions(
      from: date(0, 0), to: date(23, 59), includeAllDay: true
    )
    let result = try service.findConflicts(options: options)
    XCTAssertEqual(result.totalConflicts, 1)
  }

  func testNonOverlappingEventsNoConflicts() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Morning",
        startDate: date(9, 0), endDate: date(10, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Afternoon",
        startDate: date(14, 0), endDate: date(15, 0)
      ),
    ]
    let result = try service.findConflicts(options: dayOptions())
    XCTAssertEqual(result.totalConflicts, 0)
  }

  func testDateRangeInResult() throws {
    store.mockEvents = []
    let from = date(0, 0)
    let to = date(23, 59)
    let options = ConflictServiceOptions(from: from, to: to)
    let result = try service.findConflicts(options: options)
    XCTAssertEqual(result.dateRange.from, from)
    XCTAssertEqual(result.dateRange.to, to)
  }

  // MARK: - Helpers

  private func date(_ hour: Int, _ minute: Int) -> Date {
    var components = DateComponents()
    components.year = 2024
    components.month = 3
    components.day = 15
    components.hour = hour
    components.minute = minute
    components.second = 0
    components.timeZone = TimeZone(identifier: "America/New_York")
    return cal.date(from: components)!
  }

  private func dayOptions() -> ConflictServiceOptions {
    ConflictServiceOptions(from: date(0, 0), to: date(23, 59))
  }
}
