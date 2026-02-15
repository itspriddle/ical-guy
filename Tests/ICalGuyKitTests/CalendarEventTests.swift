import Foundation
import XCTest
@testable import ICalGuyKit

final class CalendarEventTests: XCTestCase {
    func testEventEncodesAsJSON() throws {
        let event = CalendarEvent(
            id: "evt-1",
            title: "Team Standup",
            startDate: Date(timeIntervalSince1970: 1710500400),
            endDate: Date(timeIntervalSince1970: 1710502200),
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
            attendees: ["Alice Smith", "Bob Jones"],
            isRecurring: true,
            status: "confirmed"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode([event])
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("\"title\" : \"Team Standup\""))
        XCTAssertTrue(json.contains("\"isAllDay\" : false"))
        XCTAssertTrue(json.contains("\"isRecurring\" : true"))
        XCTAssertTrue(json.contains("\"status\" : \"confirmed\""))
        XCTAssertTrue(json.contains("\"location\" : \"Conference Room B\""))
        XCTAssertTrue(json.contains("\"Alice Smith\""))
        XCTAssertTrue(json.contains("\"Bob Jones\""))
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
            startDate: Date(timeIntervalSince1970: 1710500400),
            endDate: Date(timeIntervalSince1970: 1710502200),
            isAllDay: false,
            location: nil,
            notes: nil,
            url: nil,
            calendar: CalendarInfo(
                id: "cal-1", title: "Work", type: "calDAV", source: "iCloud", color: "#1BADF8"
            ),
            attendees: [],
            isRecurring: false,
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
}
