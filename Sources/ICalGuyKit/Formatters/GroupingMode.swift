import Foundation

public enum GroupingMode: String, Sendable, CaseIterable {
  case none
  case date
  case calendar
}

public struct GroupingContext: Sendable {
  public let mode: GroupingMode
  public let showEmptyDates: Bool
  public let dateRange: DateRange?

  public init(
    mode: GroupingMode = .none,
    showEmptyDates: Bool = false,
    dateRange: DateRange? = nil
  ) {
    self.mode = mode
    self.showEmptyDates = showEmptyDates
    self.dateRange = dateRange
  }
}
