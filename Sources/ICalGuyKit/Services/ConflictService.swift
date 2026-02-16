import Foundation

public struct ConflictServiceOptions: Sendable {
  public let from: Date
  public let to: Date
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
  public let includeCalendarTypes: [String]?
  public let excludeCalendarTypes: [String]?
  public let includeAllDay: Bool

  public init(
    from: Date,
    to: Date,
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil,
    includeCalendarTypes: [String]? = nil,
    excludeCalendarTypes: [String]? = nil,
    includeAllDay: Bool = false
  ) {
    self.from = from
    self.to = to
    self.includeCalendars = includeCalendars
    self.excludeCalendars = excludeCalendars
    self.includeCalendarTypes = includeCalendarTypes
    self.excludeCalendarTypes = excludeCalendarTypes
    self.includeAllDay = includeAllDay
  }
}

public struct ConflictService: Sendable {
  private let eventService: EventService

  public init(store: any EventStoreProtocol) {
    self.eventService = EventService(store: store)
  }

  public func findConflicts(options: ConflictServiceOptions) throws -> ConflictResult {
    let events = try fetchAndFilter(options: options)
    let groups = detectConflicts(in: events)
    return ConflictResult(
      groups: groups,
      totalConflicts: groups.count,
      dateRange: DateRange(from: options.from, to: options.to)
    )
  }

  private func fetchAndFilter(options: ConflictServiceOptions) throws -> [CalendarEvent] {
    let serviceOptions = EventServiceOptions(
      from: options.from,
      to: options.to,
      includeCalendars: options.includeCalendars,
      excludeCalendars: options.excludeCalendars,
      includeCalendarTypes: options.includeCalendarTypes,
      excludeCalendarTypes: options.excludeCalendarTypes,
      excludeAllDay: !options.includeAllDay
    )
    let events = try eventService.fetchEvents(options: serviceOptions)
    return filterForScheduling(events)
  }

  /// Sweep-line algorithm: walk sorted events, group overlapping ones into clusters.
  private func detectConflicts(in events: [CalendarEvent]) -> [ConflictGroup] {
    guard events.count >= 2 else { return [] }

    var groups: [ConflictGroup] = []
    var clusterEvents: [CalendarEvent] = [events[0]]
    var clusterStart = events[0].startDate
    var clusterEnd = events[0].endDate

    for event in events.dropFirst() {
      // Strict < means adjacent events (A ends exactly when B starts) are NOT conflicts
      if event.startDate < clusterEnd {
        clusterEvents.append(event)
        clusterEnd = max(clusterEnd, event.endDate)
      } else {
        if clusterEvents.count >= 2 {
          groups.append(
            ConflictGroup(
              events: clusterEvents, windowStart: clusterStart, windowEnd: clusterEnd
            )
          )
        }
        clusterEvents = [event]
        clusterStart = event.startDate
        clusterEnd = event.endDate
      }
    }

    // Finalize last cluster
    if clusterEvents.count >= 2 {
      groups.append(
        ConflictGroup(
          events: clusterEvents, windowStart: clusterStart, windowEnd: clusterEnd
        )
      )
    }

    return groups
  }
}

// MARK: - Shared Scheduling Filter

/// Filter events for scheduling analysis (conflicts & free time).
/// Removes canceled events, free-availability events, and declined invitations.
func filterForScheduling(_ events: [CalendarEvent]) -> [CalendarEvent] {
  events.filter { event in
    // Exclude canceled events
    if event.status == "canceled" { return false }

    // Exclude show-as-free events
    if event.availability == "free" { return false }

    // Exclude events where current user declined
    if let me = event.attendees.first(where: { $0.isCurrentUser }), me.status == .declined {
      return false
    }

    return true
  }
}
