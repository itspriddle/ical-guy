import XCTest

@testable import ICalGuyKit

final class RecurrenceDescriberTests: XCTestCase {
  private let describer = RecurrenceDescriber()

  // MARK: - Daily

  func testDailyEveryDay() {
    let result = describer.describe(.init(frequency: 0, interval: 1))
    XCTAssertEqual(result, "Every day")
  }

  func testDailyEveryNDays() {
    let result = describer.describe(.init(frequency: 0, interval: 3))
    XCTAssertEqual(result, "Every 3 days")
  }

  // MARK: - Weekly

  func testWeeklySimple() {
    let result = describer.describe(.init(frequency: 1, interval: 1))
    XCTAssertEqual(result, "Every week")
  }

  func testWeeklyEveryNWeeks() {
    let result = describer.describe(.init(frequency: 1, interval: 2))
    XCTAssertEqual(result, "Every 2 weeks")
  }

  func testWeeklyOnSpecificDays() {
    let result = describer.describe(
      .init(
        frequency: 1, interval: 1,
        daysOfTheWeek: [(2, 0), (4, 0)]  // Monday, Wednesday
      ))
    XCTAssertEqual(result, "Every week on Monday and Wednesday")
  }

  func testWeeklyWeekdays() {
    let result = describer.describe(
      .init(
        frequency: 1, interval: 1,
        daysOfTheWeek: [(2, 0), (3, 0), (4, 0), (5, 0), (6, 0)]  // Mon-Fri
      ))
    XCTAssertEqual(result, "Every weekday")
  }

  func testBiweeklyOnDay() {
    let result = describer.describe(
      .init(
        frequency: 1, interval: 2,
        daysOfTheWeek: [(2, 0)]  // Monday
      ))
    XCTAssertEqual(result, "Every 2 weeks on Monday")
  }

  // MARK: - Monthly

  func testMonthlySimple() {
    let result = describer.describe(.init(frequency: 2, interval: 1))
    XCTAssertEqual(result, "Every month")
  }

  func testMonthlyEveryNMonths() {
    let result = describer.describe(.init(frequency: 2, interval: 3))
    XCTAssertEqual(result, "Every 3 months")
  }

  func testMonthlyOnNthWeekday() {
    let result = describer.describe(
      .init(
        frequency: 2, interval: 1,
        daysOfTheWeek: [(2, 1)]  // 1st Monday
      ))
    XCTAssertEqual(result, "Every month on the 1st Monday")
  }

  func testMonthlyOnLastWeekday() {
    let result = describer.describe(
      .init(
        frequency: 2, interval: 1,
        daysOfTheWeek: [(6, -1)]  // Last Friday
      ))
    XCTAssertEqual(result, "Every month on the last Friday")
  }

  func testMonthlyOnDayOfMonth() {
    let result = describer.describe(
      .init(
        frequency: 2, interval: 1,
        daysOfTheMonth: [15]
      ))
    XCTAssertEqual(result, "Every month on the 15th")
  }

  func testMonthlyOnMultipleDays() {
    let result = describer.describe(
      .init(
        frequency: 2, interval: 1,
        daysOfTheMonth: [1, 15]
      ))
    XCTAssertEqual(result, "Every month on the 1st and 15th")
  }

  // MARK: - Yearly

  func testYearlySimple() {
    let result = describer.describe(.init(frequency: 3, interval: 1))
    XCTAssertEqual(result, "Every year")
  }

  func testYearlyEveryNYears() {
    let result = describer.describe(.init(frequency: 3, interval: 2))
    XCTAssertEqual(result, "Every 2 years")
  }

  func testYearlyInSpecificMonths() {
    let result = describer.describe(
      .init(
        frequency: 3, interval: 1,
        monthsOfTheYear: [1, 6]
      ))
    XCTAssertEqual(result, "Every year in January and June")
  }

  // MARK: - Edge Cases

  func testUnknownFrequency() {
    let result = describer.describe(.init(frequency: 99, interval: 1))
    XCTAssertEqual(result, "Repeats")
  }
}
