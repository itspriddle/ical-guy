import Foundation

public struct DateGrouper: Sendable {
  private let calendar: Calendar

  public init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  public func groupByDate(
    _ events: [CalendarEvent],
    from: Date? = nil,
    to: Date? = nil,
    showEmptyDates: Bool = false
  ) -> [DateGroup] {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]

    var grouped: [String: [CalendarEvent]] = [:]

    for event in events {
      let eventStart = calendar.startOfDay(for: event.startDate)
      let eventEnd = calendar.startOfDay(for: event.endDate)

      let effectiveEnd: Date
      if event.isAllDay {
        // All-day events: EventKit sets endDate to midnight of the *next* day.
        // Subtract 1 day so a 1-day event stays in 1 bucket, a 3-day event spans 3 days.
        effectiveEnd = calendar.date(byAdding: .day, value: -1, to: eventEnd) ?? eventEnd
      } else {
        // Timed events ending exactly at midnight: don't spill into the next day
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: event.endDate)
        if endComponents.hour == 0 && endComponents.minute == 0 && endComponents.second == 0
          && eventEnd > eventStart
        {
          effectiveEnd = calendar.date(byAdding: .day, value: -1, to: eventEnd) ?? eventEnd
        } else {
          effectiveEnd = eventEnd
        }
      }

      var day = eventStart
      // Clip to query range boundaries
      if let from {
        let rangeStart = calendar.startOfDay(for: from)
        if day < rangeStart { day = rangeStart }
      }
      while day <= effectiveEnd {
        if let to {
          let rangeEnd = calendar.startOfDay(for: to)
          if day > rangeEnd { break }
        }
        let key = formatter.string(from: day)
        grouped[key, default: []].append(event)
        guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
        day = next
      }
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
}
