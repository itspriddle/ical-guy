import Foundation
import XCTest

@testable import ICalGuyKit

final class ReminderTests: XCTestCase {
  func testReminderEncodesAsJSON() throws {
    let reminder = Reminder(
      id: "rem-1",
      title: "Buy groceries",
      notes: "Milk, eggs, bread",
      url: "https://example.com",
      isCompleted: false,
      dueDate: Date(timeIntervalSince1970: 1_771_545_600),
      priority: .high,
      list: ReminderListInfo(
        id: "list-1", title: "Personal", color: "#FF9500", source: "iCloud"
      ),
      recurrence: RecurrenceInfo(isRecurring: true, description: "Every week")
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode([reminder])
    let json = String(data: data, encoding: .utf8)!

    XCTAssertTrue(json.contains("\"title\" : \"Buy groceries\""))
    XCTAssertTrue(json.contains("\"isCompleted\" : false"))
    XCTAssertTrue(json.contains("\"priority\" : \"high\""))
    XCTAssertTrue(json.contains("\"notes\" : \"Milk, eggs, bread\""))
    XCTAssertTrue(json.contains("\"Personal\""))
    XCTAssertTrue(json.contains("\"isRecurring\" : true"))
    XCTAssertTrue(json.contains("\"Every week\""))
  }

  func testReminderListInfoEncodesAsJSON() throws {
    let list = ReminderListInfo(
      id: "list-1", title: "Work", color: "#007AFF", source: "iCloud"
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    let data = try encoder.encode(list)
    let json = String(data: data, encoding: .utf8)!

    XCTAssertTrue(json.contains("\"title\":\"Work\""))
    XCTAssertTrue(json.contains("\"color\":\"#007AFF\""))
    XCTAssertTrue(json.contains("\"source\":\"iCloud\""))
  }

  func testReminderRoundTrip() throws {
    let reminder = Reminder(
      id: "rem-1",
      title: "Test",
      isCompleted: false,
      priority: .medium,
      list: ReminderListInfo(
        id: "list-1", title: "Personal", color: "#FF9500", source: "iCloud"
      )
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(reminder)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(Reminder.self, from: data)

    XCTAssertEqual(reminder, decoded)
  }

  func testPriorityEnumEncoding() throws {
    let encoder = JSONEncoder()

    for priority in [ReminderPriority.none, .low, .medium, .high] {
      let data = try encoder.encode(priority)
      let json = String(data: data, encoding: .utf8)!
      XCTAssertEqual(json, "\"\(priority.rawValue)\"")
    }
  }

  func testNilDueDateHandling() throws {
    let reminder = Reminder(
      id: "rem-1",
      title: "No due date",
      isCompleted: false,
      dueDate: nil,
      priority: .none,
      list: ReminderListInfo(
        id: "list-1", title: "Personal", color: "#FF9500", source: "iCloud"
      )
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode(reminder)
    let json = String(data: data, encoding: .utf8)!

    XCTAssertFalse(json.contains("\"dueDate\""))
  }
}
