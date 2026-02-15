import Foundation
import XCTest

@testable import ICalGuyKit

final class WeekCalculatorTests: XCTestCase {
  private var calculator: WeekCalculator!

  override func setUp() {
    super.setUp()
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    calculator = WeekCalculator(calendar: calendar)
  }

  /// Helper to build a date at noon (avoids DST edge cases).
  private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 12
    return calculator.calendar.date(from: components)!
  }

  // MARK: - Week number

  func testJan1IsAlwaysWeek1() {
    for year in 2000...2030 {
      let info = calculator.weekInfo(for: date(year, 1, 1))
      XCTAssertEqual(info.week, 1, "Jan 1, \(year) should be week 1")
    }
  }

  func testSundayStartsNewWeek() {
    // 2023-01-07 is Saturday (end of week 1), 2023-01-08 is Sunday (week 2)
    XCTAssertEqual(calculator.weekInfo(for: date(2023, 1, 7)).week, 1)
    XCTAssertEqual(calculator.weekInfo(for: date(2023, 1, 8)).week, 2)
  }

  func testWeek53Dec31Saturday() {
    // 2005: Jan 1 is Saturday, Dec 31 is Saturday → week 53
    XCTAssertEqual(calculator.weekInfo(for: date(2005, 12, 31)).week, 53)
    // 2011: Jan 1 is Saturday, Dec 31 is Saturday → week 53
    XCTAssertEqual(calculator.weekInfo(for: date(2011, 12, 31)).week, 53)
  }

  func testYearEndSpillIsWeek1() {
    // 2023-12-31 is Sunday → its week spills into 2024 → week 1 of 2024
    let info2023 = calculator.weekInfo(for: date(2023, 12, 31))
    XCTAssertEqual(info2023.week, 1)
    XCTAssertEqual(info2023.year, 2024)

    // 2024-12-30 is Monday → week spills into 2025 → week 1 of 2025
    let info2024 = calculator.weekInfo(for: date(2024, 12, 30))
    XCTAssertEqual(info2024.week, 1)
    XCTAssertEqual(info2024.year, 2025)
  }

  func testLeapYearBoundaries() {
    // 2024 is a leap year
    XCTAssertEqual(calculator.weekInfo(for: date(2024, 2, 29)).week, 9)
    XCTAssertEqual(calculator.weekInfo(for: date(2024, 3, 1)).week, 9)
  }

  // MARK: - Start/end dates

  func testWeekStartAndEnd() {
    // 2023-01-11 is Wednesday
    let info = calculator.weekInfo(for: date(2023, 1, 11))

    let start = calculator.calendar.dateComponents(
      [.year, .month, .day], from: info.startDate)
    XCTAssertEqual(start.year, 2023)
    XCTAssertEqual(start.month, 1)
    XCTAssertEqual(start.day, 8)  // Sunday

    let end = calculator.calendar.dateComponents(
      [.year, .month, .day], from: info.endDate)
    XCTAssertEqual(end.year, 2023)
    XCTAssertEqual(end.month, 1)
    XCTAssertEqual(end.day, 14)  // Saturday
  }

  func testSundayIsSelfStart() {
    let info = calculator.weekInfo(for: date(2023, 1, 8))
    let components = calculator.calendar.dateComponents(
      [.year, .month, .day], from: info.startDate)
    XCTAssertEqual(components.month, 1)
    XCTAssertEqual(components.day, 8)
  }

  func testSaturdayIsSelfEnd() {
    let info = calculator.weekInfo(for: date(2023, 1, 14))
    let components = calculator.calendar.dateComponents(
      [.year, .month, .day], from: info.endDate)
    XCTAssertEqual(components.month, 1)
    XCTAssertEqual(components.day, 14)
  }
}
