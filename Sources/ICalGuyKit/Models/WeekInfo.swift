import Foundation

public struct WeekInfo: Codable, Equatable, Sendable {
  public let week: Int
  public let year: Int
  public let startDate: Date
  public let endDate: Date

  public init(week: Int, year: Int, startDate: Date, endDate: Date) {
    self.week = week
    self.year = year
    self.startDate = startDate
    self.endDate = endDate
  }
}
