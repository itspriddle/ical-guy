import Foundation

/// Calculates Calendar.app-compatible week numbers.
///
/// Uses Sunday as the first day of the week and January 1 is always week 1,
/// matching NSCalendar/Calendar.app behavior.
public struct WeekCalculator: Sendable {
  public let calendar: Calendar

  public init(calendar: Calendar = .current) {
    var cal = calendar
    cal.firstWeekday = 1  // Sunday
    cal.minimumDaysInFirstWeek = 1  // Jan 1 is always week 1
    self.calendar = cal
  }

  public func weekInfo(for date: Date) -> WeekInfo {
    let week = calendar.component(.weekOfYear, from: date)
    let year = calendar.component(.yearForWeekOfYear, from: date)

    // Find the Sunday (start) and Saturday (end) of this week
    let weekday = calendar.component(.weekday, from: date)  // 1=Sun, 7=Sat
    let daysFromSunday = weekday - 1
    let sunday = calendar.startOfDay(
      for: calendar.date(byAdding: .day, value: -daysFromSunday, to: date)!)
    let saturday = calendar.startOfDay(
      for: calendar.date(byAdding: .day, value: 6 - daysFromSunday, to: date)!)

    return WeekInfo(week: week, year: year, startDate: sunday, endDate: saturday)
  }
}
