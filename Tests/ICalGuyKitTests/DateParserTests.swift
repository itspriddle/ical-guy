import Foundation
import XCTest

@testable import ICalGuyKit

final class DateParserTests: XCTestCase {
  private var calendar: Calendar!
  private var fixedDate: Date!
  private var parser: DateParser!

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!

    // Fixed "now": 2024-03-15 10:30:00 ET
    var components = DateComponents()
    components.year = 2024
    components.month = 3
    components.day = 15
    components.hour = 10
    components.minute = 30
    components.second = 0
    fixedDate = calendar.date(from: components)!

    parser = DateParser(calendar: calendar, now: { [fixedDate] in fixedDate! })
  }

  func testNow() throws {
    let result = try parser.parse("now")
    XCTAssertEqual(result, fixedDate)
  }

  func testToday() throws {
    let result = try parser.parse("today")
    let expected = calendar.startOfDay(for: fixedDate)
    XCTAssertEqual(result, expected)
  }

  func testTomorrow() throws {
    let result = try parser.parse("tomorrow")
    let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: fixedDate))!
    XCTAssertEqual(result, expected)
  }

  func testYesterday() throws {
    let result = try parser.parse("yesterday")
    let expected = calendar.date(
      byAdding: .day, value: -1, to: calendar.startOfDay(for: fixedDate))!
    XCTAssertEqual(result, expected)
  }

  func testTodayPlusN() throws {
    let result = try parser.parse("today+3")
    let expected = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: fixedDate))!
    XCTAssertEqual(result, expected)
  }

  func testTodayMinusN() throws {
    let result = try parser.parse("today-2")
    let expected = calendar.date(
      byAdding: .day, value: -2, to: calendar.startOfDay(for: fixedDate))!
    XCTAssertEqual(result, expected)
  }

  func testISO8601DateOnly() throws {
    let result = try parser.parse("2024-03-20")
    var components = DateComponents()
    components.year = 2024
    components.month = 3
    components.day = 20
    components.hour = 0
    components.minute = 0
    components.second = 0
    let expected = calendar.date(from: components)!
    XCTAssertEqual(result, expected)
  }

  func testCaseInsensitive() throws {
    let result = try parser.parse("TODAY")
    let expected = calendar.startOfDay(for: fixedDate)
    XCTAssertEqual(result, expected)
  }

  func testWhitespaceHandling() throws {
    let result = try parser.parse("  today  ")
    let expected = calendar.startOfDay(for: fixedDate)
    XCTAssertEqual(result, expected)
  }

  func testInvalidFormat() {
    XCTAssertThrowsError(try parser.parse("not-a-date")) { error in
      XCTAssertTrue(error is DateParseError)
    }
  }

  func testInvalidRelative() {
    XCTAssertThrowsError(try parser.parse("today+abc")) { error in
      XCTAssertTrue(error is DateParseError)
    }
  }

  func testStartOfDay() {
    let result = parser.startOfDay(fixedDate)
    let expected = calendar.startOfDay(for: fixedDate)
    XCTAssertEqual(result, expected)
  }

  func testEndOfDay() {
    let result = parser.endOfDay(fixedDate)
    let components = calendar.dateComponents([.hour, .minute, .second], from: result)
    XCTAssertEqual(components.hour, 23)
    XCTAssertEqual(components.minute, 59)
    XCTAssertEqual(components.second, 59)
  }
}
