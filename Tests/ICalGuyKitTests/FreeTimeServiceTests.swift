import Foundation
import XCTest

@testable import ICalGuyKit

final class FreeTimeServiceTests: XCTestCase {
  private var store: MockEventStore!
  private var service: FreeTimeService!
  private var cal: Calendar!

  override func setUp() {
    super.setUp()
    store = MockEventStore()
    cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/New_York")!
    service = FreeTimeService(store: store, calendar: cal)
  }

  // MARK: - Basic Free Time

  func testNoEventsEntireDayFree() throws {
    store.mockEvents = []
    let result = try service.findFreeTime(options: dayOptions())
    XCTAssertEqual(result.days.count, 1)
    XCTAssertEqual(result.days[0].totalFreeMinutes, 480)  // 8 hours
    XCTAssertEqual(result.days[0].slots.count, 1)
    XCTAssertEqual(result.days[0].slots[0].tier, .deep)
  }

  func testSingleEventTwoFreeSlots() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Meeting",
        startDate: date(12, 0), endDate: date(13, 0)
      )
    ]
    let result = try service.findFreeTime(options: dayOptions())
    XCTAssertEqual(result.days[0].slots.count, 2)
    // 9:00-12:00 = 180 min, 13:00-17:00 = 240 min
    XCTAssertEqual(result.days[0].slots[0].durationMinutes, 180)
    XCTAssertEqual(result.days[0].slots[1].durationMinutes, 240)
    XCTAssertEqual(result.days[0].totalFreeMinutes, 420)
  }

  func testBackToBackEventsMeansNoGap() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "A",
        startDate: date(9, 0), endDate: date(13, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "B",
        startDate: date(13, 0), endDate: date(17, 0)
      ),
    ]
    let result = try service.findFreeTime(options: dayOptions())
    XCTAssertEqual(result.days[0].slots.count, 0)
    XCTAssertEqual(result.days[0].totalFreeMinutes, 0)
  }

  func testOverlappingEventsMerged() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "A",
        startDate: date(10, 0), endDate: date(12, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "B",
        startDate: date(11, 0), endDate: date(13, 0)
      ),
    ]
    let result = try service.findFreeTime(options: dayOptions())
    // 9:00-10:00 = 60 min, 13:00-17:00 = 240 min
    XCTAssertEqual(result.days[0].slots.count, 2)
    XCTAssertEqual(result.days[0].slots[0].durationMinutes, 60)
    XCTAssertEqual(result.days[0].slots[1].durationMinutes, 240)
  }

  // MARK: - Min Duration Filter

  func testMinDurationFiltersShortSlots() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "A",
        startDate: date(9, 0), endDate: date(9, 15)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "B",
        startDate: date(9, 30), endDate: date(17, 0)
      ),
    ]
    // Gap is 9:15-9:30 = 15 min, less than default 30 min
    let result = try service.findFreeTime(options: dayOptions())
    // Only the gap before the first event (0 min since it starts at window start)
    // 9:15-9:30 = 15 min (filtered), no other gaps
    XCTAssertEqual(result.days[0].slots.count, 0)
  }

  func testMinDurationCustomValue() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "A",
        startDate: date(10, 0), endDate: date(10, 45)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "B",
        startDate: date(11, 30), endDate: date(17, 0)
      ),
    ]
    // Gap: 9:00-10:00 = 60min, 10:45-11:30 = 45min
    let options = FreeTimeServiceOptions(
      from: date(0, 0), to: date(23, 59), minDuration: 60
    )
    let result = try service.findFreeTime(options: options)
    // Only 9:00-10:00 passes the 60min filter
    XCTAssertEqual(result.days[0].slots.count, 1)
    XCTAssertEqual(result.days[0].slots[0].durationMinutes, 60)
  }

  // MARK: - Working Hours

  func testCustomWorkingHours() throws {
    store.mockEvents = []
    let wh = WorkingHours(startHour: 8, startMinute: 0, endHour: 18, endMinute: 0)
    let options = FreeTimeServiceOptions(
      from: date(0, 0), to: date(23, 59), workingHours: wh
    )
    let result = try service.findFreeTime(options: options)
    XCTAssertEqual(result.days[0].totalFreeMinutes, 600)  // 10 hours
  }

  // MARK: - Duration Tiers

  func testDurationTierAssignment() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Block1",
        startDate: date(9, 30), endDate: date(10, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Block2",
        startDate: date(11, 0), endDate: date(12, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e3", title: "Block3",
        startDate: date(13, 0), endDate: date(15, 0)
      ),
    ]
    let result = try service.findFreeTime(options: dayOptions())
    // 9:00-9:30 = 30min (short), 10:00-11:00 = 60min (focus),
    // 12:00-13:00 = 60min (focus), 15:00-17:00 = 120min (deep)
    XCTAssertEqual(result.days[0].slots.count, 4)
    XCTAssertEqual(result.days[0].slots[0].tier, .short)
    XCTAssertEqual(result.days[0].slots[1].tier, .focus)
    XCTAssertEqual(result.days[0].slots[2].tier, .focus)
    XCTAssertEqual(result.days[0].slots[3].tier, .deep)
  }

  // MARK: - Multi-day

  func testMultipleDays() throws {
    store.mockEvents = []
    let from = date(0, 0)
    let cal2 = cal!
    let to = cal2.date(byAdding: .day, value: 2, to: from)!
    let options = FreeTimeServiceOptions(from: from, to: to)
    let result = try service.findFreeTime(options: options)
    XCTAssertEqual(result.days.count, 3)
    XCTAssertEqual(result.totalFreeMinutes, 480 * 3)
  }

  // MARK: - Now clipping

  func testFromNowClipsWindowStart() throws {
    store.mockEvents = []
    // Start at 2pm — should clip working hours to 2pm-5pm = 180min
    let from = date(14, 0)
    let options = FreeTimeServiceOptions(
      from: from, to: date(23, 59)
    )
    let result = try service.findFreeTime(options: options)
    XCTAssertEqual(result.days[0].totalFreeMinutes, 180)
  }

  func testFromNowAfterWorkingHoursNoSlots() throws {
    store.mockEvents = []
    // Start at 6pm — after working hours end (5pm)
    let from = date(18, 0)
    let options = FreeTimeServiceOptions(
      from: from, to: date(23, 59)
    )
    let result = try service.findFreeTime(options: options)
    XCTAssertEqual(result.days[0].slots.count, 0)
  }

  // MARK: - Scheduling Filters

  func testCanceledEventsExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Canceled",
        startDate: date(10, 0), endDate: date(14, 0), status: 3
      )
    ]
    let result = try service.findFreeTime(options: dayOptions())
    // Canceled event doesn't block time
    XCTAssertEqual(result.days[0].totalFreeMinutes, 480)
  }

  func testFreeAvailabilityExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Show As Free",
        startDate: date(10, 0), endDate: date(14, 0), availability: 1
      )
    ]
    let result = try service.findFreeTime(options: dayOptions())
    XCTAssertEqual(result.days[0].totalFreeMinutes, 480)
  }

  func testDeclinedEventsExcluded() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Declined",
        startDate: date(10, 0), endDate: date(14, 0),
        attendees: [
          MockEventStore.sampleAttendee(
            name: "Me", status: 3, isCurrentUser: true
          )
        ]
      )
    ]
    let result = try service.findFreeTime(options: dayOptions())
    XCTAssertEqual(result.days[0].totalFreeMinutes, 480)
  }

  // MARK: - Events Outside Working Hours

  func testEventOutsideWorkingHoursIgnored() throws {
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Early Morning",
        startDate: date(7, 0), endDate: date(8, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Late Evening",
        startDate: date(18, 0), endDate: date(19, 0)
      ),
    ]
    let result = try service.findFreeTime(options: dayOptions())
    XCTAssertEqual(result.days[0].totalFreeMinutes, 480)
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

  private func dayOptions() -> FreeTimeServiceOptions {
    FreeTimeServiceOptions(from: date(0, 0), to: date(23, 59))
  }
}
