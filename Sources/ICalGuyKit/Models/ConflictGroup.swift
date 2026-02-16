import Foundation

public struct DateRange: Codable, Equatable, Sendable {
  public let from: Date
  public let to: Date

  public init(from: Date, to: Date) {
    self.from = from
    self.to = to
  }
}

public struct ConflictGroup: Codable, Equatable, Sendable {
  public let events: [CalendarEvent]
  public let windowStart: Date
  public let windowEnd: Date

  public init(events: [CalendarEvent], windowStart: Date, windowEnd: Date) {
    self.events = events
    self.windowStart = windowStart
    self.windowEnd = windowEnd
  }
}

public struct ConflictResult: Codable, Equatable, Sendable {
  public let groups: [ConflictGroup]
  public let totalConflicts: Int
  public let dateRange: DateRange

  public init(groups: [ConflictGroup], totalConflicts: Int, dateRange: DateRange) {
    self.groups = groups
    self.totalConflicts = totalConflicts
    self.dateRange = dateRange
  }
}
