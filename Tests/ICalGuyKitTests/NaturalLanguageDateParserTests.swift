import Foundation
import XCTest

@testable import ICalGuyKit

final class NaturalLanguageDateParserTests: XCTestCase {
  private var parser: DateParser!
  private var calendar: Calendar!

  override func setUp() {
    super.setUp()
    calendar = Calendar.current
    parser = DateParser()
  }

  // MARK: - Absolute dates

  func testJune10() throws {
    let result = try parser.parse("june 10")
    let components = calendar.dateComponents([.month, .day], from: result)
    XCTAssertEqual(components.month, 6)
    XCTAssertEqual(components.day, 10)
  }

  func testMarch1_2026() throws {
    let result = try parser.parse("march 1, 2026")
    let components = calendar.dateComponents([.year, .month, .day], from: result)
    XCTAssertEqual(components.year, 2026)
    XCTAssertEqual(components.month, 3)
    XCTAssertEqual(components.day, 1)
  }

  func testJune10At6pm() throws {
    let result = try parser.parse("june 10 at 6pm")
    let components = calendar.dateComponents([.month, .day, .hour], from: result)
    XCTAssertEqual(components.month, 6)
    XCTAssertEqual(components.day, 10)
    XCTAssertEqual(components.hour, 18)
  }

  func testDecember25() throws {
    let result = try parser.parse("december 25")
    let components = calendar.dateComponents([.month, .day], from: result)
    XCTAssertEqual(components.month, 12)
    XCTAssertEqual(components.day, 25)
  }

  func testCaseInsensitivity() throws {
    let result = try parser.parse("June 10 at 6PM")
    let components = calendar.dateComponents([.month, .day, .hour], from: result)
    XCTAssertEqual(components.month, 6)
    XCTAssertEqual(components.day, 10)
    XCTAssertEqual(components.hour, 18)
  }

  // MARK: - Relative dates

  func testTomorrowAtNoon() throws {
    let result = try parser.parse("tomorrow at noon")
    let expectedDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
    let resultComponents = calendar.dateComponents([.year, .month, .day, .hour], from: result)
    let expectedComponents = calendar.dateComponents([.year, .month, .day], from: expectedDate)
    XCTAssertEqual(resultComponents.year, expectedComponents.year)
    XCTAssertEqual(resultComponents.month, expectedComponents.month)
    XCTAssertEqual(resultComponents.day, expectedComponents.day)
    XCTAssertEqual(resultComponents.hour, 12)
  }

  func testNextFriday() throws {
    let result = try parser.parse("next friday")
    let components = calendar.dateComponents([.weekday], from: result)
    XCTAssertEqual(components.weekday, 6)  // Friday = 6 in Calendar
    XCTAssertGreaterThan(result, Date())
  }

  // MARK: - Rejection tests

  func testPartialMatchRejects() {
    XCTAssertThrowsError(try parser.parse("meet me tomorrow")) { error in
      XCTAssertTrue(error is DateParseError)
    }
  }

  func testNonsenseRejects() {
    XCTAssertThrowsError(try parser.parse("not-a-date-at-all")) { error in
      XCTAssertTrue(error is DateParseError)
    }
  }
}
