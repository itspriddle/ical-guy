import Foundation

public struct Birthday: Codable, Equatable, Sendable {
  public let name: String
  public let date: Date
  public let calendar: CalendarInfo

  public init(name: String, date: Date, calendar: CalendarInfo) {
    self.name = name
    self.date = date
    self.calendar = calendar
  }
}
