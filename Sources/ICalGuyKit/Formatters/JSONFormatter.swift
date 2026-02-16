import Foundation

public struct JSONFormatter: OutputFormatter, Sendable {
  private let pretty: Bool
  private let grouping: GroupingContext

  public init(pretty: Bool, grouping: GroupingContext = GroupingContext()) {
    self.pretty = pretty
    self.grouping = grouping
  }

  public func formatEvents(_ events: [CalendarEvent]) throws -> String {
    switch grouping.mode {
    case .none:
      return try encode(events)
    case .date:
      let grouper = EventGrouper()
      let groups = grouper.groupByDate(
        events,
        from: grouping.dateRange?.from,
        to: grouping.dateRange?.to,
        showEmptyDates: grouping.showEmptyDates
      )
      return try encode(groups)
    case .calendar:
      let grouper = EventGrouper()
      return try encode(grouper.groupByCalendar(events))
    }
  }

  public func formatCalendars(_ calendars: [CalendarInfo]) throws -> String {
    try encode(calendars)
  }

  public func formatReminders(_ reminders: [Reminder]) throws -> String {
    switch grouping.mode {
    case .calendar:
      let grouper = EventGrouper()
      return try encode(grouper.groupRemindersByList(reminders))
    default:
      return try encode(reminders)
    }
  }

  public func formatReminderLists(_ lists: [ReminderListInfo]) throws -> String {
    try encode(lists)
  }

  public func formatBirthdays(_ birthdays: [Birthday]) throws -> String {
    try encode(birthdays)
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
