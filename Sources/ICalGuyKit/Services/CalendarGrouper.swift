import Foundation

public struct CalendarGrouper: Sendable {
  public init() {}

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
}
