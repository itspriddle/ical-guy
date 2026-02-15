import Foundation
import XCTest

@testable import ICalGuyKit

final class CalendarEventTests: XCTestCase {
  func testEventEncodesAsJSON() throws {
    let event = CalendarEvent(
      id: "evt-1",
      title: "Team Standup",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: "Conference Room B",
      notes: "Weekly sync",
      url: nil,
      calendar: CalendarInfo(
        id: "cal-1",
        title: "Work",
        type: "calDAV",
        source: "iCloud",
        color: "#1BADF8"
      ),
      attendees: [
        Attendee(
          name: "Alice Smith", email: "alice@example.com",
          status: .accepted, role: .required, isCurrentUser: false
        ),
        Attendee(
          name: "Bob Jones", email: "bob@example.com",
          status: .tentative, role: .optional, isCurrentUser: false
        ),
      ],
      organizer: Organizer(name: "Alice Smith", email: "alice@example.com"),
      recurrence: RecurrenceInfo(isRecurring: true, description: "Every weekday"),
      status: "confirmed",
      availability: "busy"
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode([event])
    let json = String(data: data, encoding: .utf8)!

    XCTAssertTrue(json.contains("\"title\" : \"Team Standup\""))
    XCTAssertTrue(json.contains("\"isAllDay\" : false"))
    XCTAssertTrue(json.contains("\"status\" : \"confirmed\""))
    XCTAssertTrue(json.contains("\"location\" : \"Conference Room B\""))
    XCTAssertTrue(json.contains("\"Alice Smith\""))
    XCTAssertTrue(json.contains("\"Bob Jones\""))
    XCTAssertTrue(json.contains("\"accepted\""))
    XCTAssertTrue(json.contains("\"tentative\""))
    XCTAssertTrue(json.contains("\"isRecurring\" : true"))
    XCTAssertTrue(json.contains("\"Every weekday\""))
    XCTAssertTrue(json.contains("\"availability\" : \"busy\""))
  }

  func testCalendarInfoEncodesAsJSON() throws {
    let cal = CalendarInfo(
      id: "cal-1",
      title: "Work",
      type: "calDAV",
      source: "iCloud",
      color: "#1BADF8"
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    let data = try encoder.encode(cal)
    let json = String(data: data, encoding: .utf8)!

    XCTAssertTrue(json.contains("\"title\":\"Work\""))
    XCTAssertTrue(json.contains("\"type\":\"calDAV\""))
    XCTAssertTrue(json.contains("\"source\":\"iCloud\""))
    XCTAssertTrue(json.contains("\"color\":\"#1BADF8\""))
  }

  func testEventRoundTrip() throws {
    let event = CalendarEvent(
      id: "evt-1",
      title: "Test",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: nil,
      notes: nil,
      url: nil,
      calendar: CalendarInfo(
        id: "cal-1", title: "Work", type: "calDAV", source: "iCloud", color: "#1BADF8"
      ),
      status: "none"
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(event)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(CalendarEvent.self, from: data)

    XCTAssertEqual(event, decoded)
  }

  func testAttendeeEncodesAsJSON() throws {
    let attendee = Attendee(
      name: "Test User",
      email: "test@example.com",
      status: .accepted,
      role: .required,
      isCurrentUser: true
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(attendee)
    let json = String(data: data, encoding: .utf8)!

    XCTAssertTrue(json.contains("\"status\":\"accepted\""))
    XCTAssertTrue(json.contains("\"role\":\"required\""))
    XCTAssertTrue(json.contains("\"isCurrentUser\":true"))
  }

  func testRecurrenceInfoEncodes() throws {
    let recurring = RecurrenceInfo(isRecurring: true, description: "Every 2 weeks on Monday")
    let notRecurring = RecurrenceInfo(isRecurring: false)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    let data1 = try encoder.encode(recurring)
    let json1 = String(data: data1, encoding: .utf8)!
    XCTAssertTrue(json1.contains("\"isRecurring\":true"))
    XCTAssertTrue(json1.contains("\"Every 2 weeks on Monday\""))

    let data2 = try encoder.encode(notRecurring)
    let json2 = String(data: data2, encoding: .utf8)!
    XCTAssertTrue(json2.contains("\"isRecurring\":false"))
  }
}
