import Foundation

/// Builds human-readable recurrence descriptions from rule components.
///
/// Frequency values (matching EKRecurrenceFrequency.rawValue):
///   0 = daily, 1 = weekly, 2 = monthly, 3 = yearly
///
/// Day-of-week values (matching EKRecurrenceDayOfWeek):
///   1 = Sunday, 2 = Monday, ..., 7 = Saturday
public struct RecurrenceDescriber: Sendable {
  public init() {}

  public struct RuleComponents: Sendable {
    public let frequency: Int
    public let interval: Int
    public let daysOfTheWeek: [(dayOfWeek: Int, weekNumber: Int)]?
    public let daysOfTheMonth: [Int]?
    public let monthsOfTheYear: [Int]?

    public init(
      frequency: Int,
      interval: Int,
      daysOfTheWeek: [(dayOfWeek: Int, weekNumber: Int)]? = nil,
      daysOfTheMonth: [Int]? = nil,
      monthsOfTheYear: [Int]? = nil
    ) {
      self.frequency = frequency
      self.interval = interval
      self.daysOfTheWeek = daysOfTheWeek
      self.daysOfTheMonth = daysOfTheMonth
      self.monthsOfTheYear = monthsOfTheYear
    }
  }

  public func describe(_ components: RuleComponents) -> String {
    switch components.frequency {
    case 0: return describeDaily(components)
    case 1: return describeWeekly(components)
    case 2: return describeMonthly(components)
    case 3: return describeYearly(components)
    default: return "Repeats"
    }
  }

  // MARK: - Daily

  private func describeDaily(_ rule: RuleComponents) -> String {
    if rule.interval == 1 {
      return "Every day"
    }
    return "Every \(rule.interval) days"
  }

  // MARK: - Weekly

  private func describeWeekly(_ rule: RuleComponents) -> String {
    let prefix = rule.interval == 1 ? "Every week" : "Every \(rule.interval) weeks"

    guard let days = rule.daysOfTheWeek, !days.isEmpty else {
      return prefix
    }

    let dayNames = days.map { dayName($0.dayOfWeek) }

    if dayNames.count == 5, !dayNames.contains("Saturday"), !dayNames.contains("Sunday") {
      return rule.interval == 1 ? "Every weekday" : "\(prefix) on weekdays"
    }

    return "\(prefix) on \(joinedList(dayNames))"
  }

  // MARK: - Monthly

  private func describeMonthly(_ rule: RuleComponents) -> String {
    let prefix = rule.interval == 1 ? "Every month" : "Every \(rule.interval) months"

    if let days = rule.daysOfTheWeek, let first = days.first, first.weekNumber != 0 {
      let ordinal = ordinalString(first.weekNumber)
      let name = dayName(first.dayOfWeek)
      return "\(prefix) on the \(ordinal) \(name)"
    }

    if let monthDays = rule.daysOfTheMonth, !monthDays.isEmpty {
      let dayStrings = monthDays.map { ordinalString($0) }
      return "\(prefix) on the \(joinedList(dayStrings))"
    }

    return prefix
  }

  // MARK: - Yearly

  private func describeYearly(_ rule: RuleComponents) -> String {
    let prefix = rule.interval == 1 ? "Every year" : "Every \(rule.interval) years"

    if let months = rule.monthsOfTheYear, !months.isEmpty {
      let monthNames = months.map { monthName($0) }
      return "\(prefix) in \(joinedList(monthNames))"
    }

    return prefix
  }

  // MARK: - Helpers

  private func dayName(_ day: Int) -> String {
    switch day {
    case 1: return "Sunday"
    case 2: return "Monday"
    case 3: return "Tuesday"
    case 4: return "Wednesday"
    case 5: return "Thursday"
    case 6: return "Friday"
    case 7: return "Saturday"
    default: return "Day \(day)"
    }
  }

  private static let monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ]

  private func monthName(_ month: Int) -> String {
    guard (1...12).contains(month) else { return "Month \(month)" }
    return Self.monthNames[month - 1]
  }

  private func ordinalString(_ n: Int) -> String {
    if n == -1 { return "last" }
    let suffix: String
    let absN = abs(n)
    switch absN % 100 {
    case 11, 12, 13: suffix = "th"
    default:
      switch absN % 10 {
      case 1: suffix = "st"
      case 2: suffix = "nd"
      case 3: suffix = "rd"
      default: suffix = "th"
      }
    }
    return "\(absN)\(suffix)"
  }

  private func joinedList(_ items: [String]) -> String {
    switch items.count {
    case 0: return ""
    case 1: return items[0]
    case 2: return "\(items[0]) and \(items[1])"
    default: return items.dropLast().joined(separator: ", ") + ", and " + items.last!
    }
  }
}
