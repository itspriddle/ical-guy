import Foundation

public struct DateGroup: Codable, Equatable, Sendable {
  public let date: String
  public let events: [CalendarEvent]

  public init(date: String, events: [CalendarEvent]) {
    self.date = date
    self.events = events
  }
}

public struct CalendarGroup: Codable, Equatable, Sendable {
  public let calendar: CalendarInfo
  public let events: [CalendarEvent]

  public init(calendar: CalendarInfo, events: [CalendarEvent]) {
    self.calendar = calendar
    self.events = events
  }
}

public struct ReminderListGroup: Codable, Equatable, Sendable {
  public let list: ReminderListInfo
  public let reminders: [Reminder]

  public init(list: ReminderListInfo, reminders: [Reminder]) {
    self.list = list
    self.reminders = reminders
  }
}
