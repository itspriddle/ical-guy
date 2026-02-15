import Foundation
import XCTest

@testable import ICalGuyKit

final class MeetingServiceTests: XCTestCase {
  private var store: MockEventStore!
  private var calendar: Calendar!

  override func setUp() {
    super.setUp()
    store = MockEventStore()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
  }

  func testCurrentMeetingFound() throws {
    let now = date(2024, 3, 15, 9, 15)
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Standup",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 9, 30),
        url: "https://meet.google.com/abc-defg-hij"
      )
    ]

    let service = MeetingService(store: store, now: { now })
    let context = try service.currentMeeting()

    XCTAssertNotNil(context)
    XCTAssertEqual(context?.event.title, "Standup")
    XCTAssertTrue(context!.isNow)
    XCTAssertNotNil(context?.timeRemaining)
    XCTAssertNil(context?.timeUntil)
  }

  func testCurrentMeetingNilWhenNoMeetingURL() throws {
    let now = date(2024, 3, 15, 9, 15)
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Lunch",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0)
        // No meeting URL
      )
    ]

    let service = MeetingService(store: store, now: { now })
    let context = try service.currentMeeting()

    XCTAssertNil(context)
  }

  func testNextMeetingFound() throws {
    let now = date(2024, 3, 15, 8, 30)
    store.mockEvents = [
      MockEventStore.sampleEvent(
        title: "Standup",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 9, 30),
        url: "https://meet.google.com/abc-defg-hij"
      )
    ]

    let service = MeetingService(store: store, now: { now })
    let context = try service.nextMeeting()

    XCTAssertNotNil(context)
    XCTAssertEqual(context?.event.title, "Standup")
    XCTAssertFalse(context!.isNow)
    XCTAssertNil(context?.timeRemaining)
    XCTAssertNotNil(context?.timeUntil)
  }

  func testNextMeetingSkipsCurrentMeeting() throws {
    let now = date(2024, 3, 15, 9, 15)
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Current Meeting",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 9, 30),
        url: "https://meet.google.com/aaa-bbbb-ccc"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "Next Meeting",
        startDate: date(2024, 3, 15, 10, 0),
        endDate: date(2024, 3, 15, 11, 0),
        url: "https://meet.google.com/ddd-eeee-fff"
      ),
    ]

    let service = MeetingService(store: store, now: { now })
    let context = try service.nextMeeting()

    XCTAssertEqual(context?.event.title, "Next Meeting")
  }

  func testTodaysMeetings() throws {
    let now = date(2024, 3, 15, 8, 0)
    store.mockEvents = [
      MockEventStore.sampleEvent(
        id: "e1", title: "Meeting With URL",
        startDate: date(2024, 3, 15, 9, 0),
        endDate: date(2024, 3, 15, 10, 0),
        url: "https://meet.google.com/abc-defg-hij"
      ),
      MockEventStore.sampleEvent(
        id: "e2", title: "No URL Event",
        startDate: date(2024, 3, 15, 11, 0),
        endDate: date(2024, 3, 15, 12, 0)
      ),
      MockEventStore.sampleEvent(
        id: "e3", title: "Another Meeting",
        startDate: date(2024, 3, 15, 14, 0),
        endDate: date(2024, 3, 15, 15, 0),
        notes: "Join: https://zoom.us/j/123456789"
      ),
    ]

    let service = MeetingService(store: store, now: { now })
    let meetings = try service.todaysMeetings()

    XCTAssertEqual(meetings.count, 2)
    XCTAssertEqual(meetings[0].title, "Meeting With URL")
    XCTAssertEqual(meetings[1].title, "Another Meeting")
  }

  func testNoMeetingsReturnsEmpty() throws {
    let now = date(2024, 3, 15, 8, 0)
    store.mockEvents = []

    let service = MeetingService(store: store, now: { now })
    let meetings = try service.todaysMeetings()

    XCTAssertTrue(meetings.isEmpty)
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
