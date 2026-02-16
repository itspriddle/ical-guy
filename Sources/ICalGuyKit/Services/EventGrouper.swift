import Foundation

public struct EventGrouper: Sendable {
  private let calendar: Calendar

  public init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  // MARK: - Date Grouping

  public func groupByDate(
    _ events: [CalendarEvent],
    from: Date? = nil,
    to: Date? = nil,
    showEmptyDates: Bool = false
  ) -> [DateGroup] {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]

    let grouped = Dictionary(grouping: events) { event -> String in
      let day = calendar.startOfDay(for: event.startDate)
      return formatter.string(from: day)
    }

    if showEmptyDates, let from, let to {
      return buildDateRange(from: from, to: to, formatter: formatter, grouped: grouped)
    }

    return grouped.keys.sorted().map { dateKey in
      DateGroup(date: dateKey, events: grouped[dateKey] ?? [])
    }
  }

  private func buildDateRange(
    from: Date,
    to: Date,
    formatter: ISO8601DateFormatter,
    grouped: [String: [CalendarEvent]]
  ) -> [DateGroup] {
    var result: [DateGroup] = []
    var current = calendar.startOfDay(for: from)
    let end = calendar.startOfDay(for: to)

    while current <= end {
      let key = formatter.string(from: current)
      let events = grouped[key] ?? []
      result.append(DateGroup(date: key, events: events))
      guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
      current = next
    }

    return result
  }

  // MARK: - Calendar Grouping

  public func groupByCalendar(_ events: [CalendarEvent]) -> [CalendarGroup] {
    let grouped = Dictionary(grouping: events) { $0.calendar.id }

    return grouped.values
      .map { events in
        CalendarGroup(
          calendar: events[0].calendar,
          events: events.sorted { a, b in
            a.startDate < b.startDate
          })
      }
      .sorted {
        $0.calendar.title.localizedCaseInsensitiveCompare($1.calendar.title) == .orderedAscending
      }
  }

  // MARK: - Reminder List Grouping

  public func groupRemindersByList(_ reminders: [Reminder]) -> [ReminderListGroup] {
    let grouped = Dictionary(grouping: reminders) { $0.list.id }

    return grouped.values
      .map { reminders in
        ReminderListGroup(list: reminders[0].list, reminders: reminders)
      }
      .sorted {
        $0.list.title.localizedCaseInsensitiveCompare($1.list.title) == .orderedAscending
      }
  }
}
