import Foundation

public struct JSONFormatter: OutputFormatter, Sendable {
  private let pretty: Bool

  public init(pretty: Bool) {
    self.pretty = pretty
  }

  public func formatEvents(_ events: [CalendarEvent]) throws -> String {
    try encode(events)
  }

  public func formatCalendars(_ calendars: [CalendarInfo]) throws -> String {
    try encode(calendars)
  }

  public func formatReminders(_ reminders: [Reminder]) throws -> String {
    try encode(reminders)
  }

  public func formatReminderLists(_ lists: [ReminderListInfo]) throws -> String {
    try encode(lists)
  }

  private func encode<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    if pretty {
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    } else {
      encoder.outputFormatting = [.sortedKeys]
    }
    let data = try encoder.encode(value)
    return String(data: data, encoding: .utf8)!
  }
}
