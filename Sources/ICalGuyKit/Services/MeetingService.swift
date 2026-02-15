import Foundation

public struct MeetingService: Sendable {
  private let store: any EventStoreProtocol
  private let meetingURLParser = MeetingURLParser()
  private let now: @Sendable () -> Date

  public init(store: any EventStoreProtocol, now: @escaping @Sendable () -> Date = { Date() }) {
    self.store = store
    self.now = now
  }

  /// Find the current meeting (happening right now with a meeting URL).
  public func currentMeeting(
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil
  ) throws -> MeetingContext? {
    let currentTime = now()
    let events = try fetchTodaysMeetings(
      includeCalendars: includeCalendars,
      excludeCalendars: excludeCalendars
    )

    guard
      let event = events.first(where: {
        $0.startDate <= currentTime && $0.endDate > currentTime
      })
    else {
      return nil
    }

    return MeetingContext(
      event: event,
      timeRemaining: event.endDate.timeIntervalSince(currentTime),
      timeUntil: nil
    )
  }

  /// Find the next upcoming meeting (with a meeting URL).
  public func nextMeeting(
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil
  ) throws -> MeetingContext? {
    let currentTime = now()
    let events = try fetchTodaysMeetings(
      includeCalendars: includeCalendars,
      excludeCalendars: excludeCalendars
    )

    guard let event = events.first(where: { $0.startDate > currentTime }) else {
      return nil
    }

    return MeetingContext(
      event: event,
      timeRemaining: nil,
      timeUntil: event.startDate.timeIntervalSince(currentTime)
    )
  }

  /// List today's meetings (events with meeting URLs).
  public func todaysMeetings(
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil
  ) throws -> [CalendarEvent] {
    try fetchTodaysMeetings(
      includeCalendars: includeCalendars,
      excludeCalendars: excludeCalendars
    )
  }

  private func fetchTodaysMeetings(
    includeCalendars: [String]?,
    excludeCalendars: [String]?
  ) throws -> [CalendarEvent] {
    let currentTime = now()
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: currentTime)

    var endComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
    endComponents.hour = 23
    endComponents.minute = 59
    endComponents.second = 59
    let endOfDay = calendar.date(from: endComponents)!

    let service = EventService(store: store)
    let options = EventServiceOptions(
      from: startOfDay,
      to: endOfDay,
      includeCalendars: includeCalendars,
      excludeCalendars: excludeCalendars,
      excludeAllDay: true
    )

    let events = try service.fetchEvents(options: options)
    return events.filter { $0.meetingUrl != nil }
  }
}
