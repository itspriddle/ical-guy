import Foundation

public struct EventServiceOptions: Sendable {
  public let from: Date
  public let to: Date
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
  public let includeCalendarTypes: [String]?
  public let excludeCalendarTypes: [String]?
  public let excludeAllDay: Bool
  public let limit: Int?

  public init(
    from: Date,
    to: Date,
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil,
    includeCalendarTypes: [String]? = nil,
    excludeCalendarTypes: [String]? = nil,
    excludeAllDay: Bool = false,
    limit: Int? = nil
  ) {
    self.from = from
    self.to = to
    self.includeCalendars = includeCalendars
    self.excludeCalendars = excludeCalendars
    self.includeCalendarTypes = includeCalendarTypes
    self.excludeCalendarTypes = excludeCalendarTypes
    self.excludeAllDay = excludeAllDay
    self.limit = limit
  }
}

public struct EventService: Sendable {
  private let store: any EventStoreProtocol
  private let meetingURLParser = MeetingURLParser()

  public init(store: any EventStoreProtocol) {
    self.store = store
  }

  public func fetchEvents(options: EventServiceOptions) throws -> [CalendarEvent] {
    let query = EventQuery(
      startDate: options.from,
      endDate: options.to
    )

    var rawEvents = try store.events(matching: query)

    // Filter by included calendars
    if let include = options.includeCalendars, !include.isEmpty {
      let includeSet = Set(include.map { $0.lowercased() })
      rawEvents = rawEvents.filter { includeSet.contains($0.calendarTitle.lowercased()) }
    }

    // Filter by excluded calendars
    if let exclude = options.excludeCalendars, !exclude.isEmpty {
      let excludeSet = Set(exclude.map { $0.lowercased() })
      rawEvents = rawEvents.filter { !excludeSet.contains($0.calendarTitle.lowercased()) }
    }

    // Filter by included calendar types
    if let includeTypes = options.includeCalendarTypes, !includeTypes.isEmpty {
      let typeSet = Set(includeTypes.map { $0.lowercased() })
      rawEvents = rawEvents.filter { matchesCalendarType($0, types: typeSet) }
    }

    // Filter by excluded calendar types
    if let excludeTypes = options.excludeCalendarTypes, !excludeTypes.isEmpty {
      let typeSet = Set(excludeTypes.map { $0.lowercased() })
      rawEvents = rawEvents.filter { !matchesCalendarType($0, types: typeSet) }
    }

    // Filter all-day events
    if options.excludeAllDay {
      rawEvents = rawEvents.filter { !$0.isAllDay }
    }

    // Sort by start date, then title
    rawEvents.sort { a, b in
      if a.startDate == b.startDate {
        return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
      }
      return a.startDate < b.startDate
    }

    // Apply limit
    if let limit = options.limit, limit > 0 {
      rawEvents = Array(rawEvents.prefix(limit))
    }

    return rawEvents.map { convertToCalendarEvent($0) }
  }

  public func fetchBirthdays(from: Date, to: Date, limit: Int? = nil) throws -> [Birthday] {
    let query = EventQuery(startDate: from, endDate: to)
    var rawEvents = try store.events(matching: query)

    // Filter to birthday calendars only
    rawEvents = rawEvents.filter { $0.calendarType == "birthday" }

    // Sort by date, then name
    rawEvents.sort { a, b in
      if a.startDate == b.startDate {
        return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
      }
      return a.startDate < b.startDate
    }

    // Apply limit
    if let limit, limit > 0 {
      rawEvents = Array(rawEvents.prefix(limit))
    }

    return rawEvents.map { raw in
      Birthday(
        name: raw.title,
        date: raw.startDate,
        calendar: CalendarInfo(
          id: raw.calendarId,
          title: raw.calendarTitle,
          type: raw.calendarType,
          source: raw.calendarSource,
          color: raw.calendarColor
        )
      )
    }
  }

  public func fetchCalendars() throws -> [CalendarInfo] {
    try store.calendars().map { raw in
      CalendarInfo(
        id: raw.id,
        title: raw.title,
        type: raw.type,
        source: raw.source,
        color: raw.color
      )
    }
  }

  // MARK: - Calendar Type Matching

  private func matchesCalendarType(_ event: RawEvent, types: Set<String>) -> Bool {
    let eventType = event.calendarType.lowercased()
    if types.contains(eventType) { return true }
    // "icloud" is a virtual alias for calDAV calendars with iCloud source
    if types.contains("icloud")
      && eventType == "caldav"
      && event.calendarSource.lowercased().contains("icloud")
    {
      return true
    }
    return false
  }

  // MARK: - Conversion

  private func convertToCalendarEvent(_ raw: RawEvent) -> CalendarEvent {
    CalendarEvent(
      id: raw.id,
      title: raw.title,
      startDate: raw.startDate,
      endDate: raw.endDate,
      isAllDay: raw.isAllDay,
      location: raw.location,
      notes: raw.notes,
      url: raw.url,
      meetingUrl: meetingURLParser.extractMeetingURL(
        url: raw.url, location: raw.location, notes: raw.notes
      ),
      calendar: CalendarInfo(
        id: raw.calendarId,
        title: raw.calendarTitle,
        type: raw.calendarType,
        source: raw.calendarSource,
        color: raw.calendarColor
      ),
      attendees: raw.attendees.map { convertAttendee($0) },
      organizer: convertOrganizer(raw.organizer),
      recurrence: RecurrenceInfo(
        isRecurring: raw.isRecurring,
        description: raw.recurrenceDescription
      ),
      status: statusString(from: raw.status),
      availability: availabilityString(from: raw.availability),
      timeZone: raw.timeZone,
      creationDate: raw.creationDate,
      lastModifiedDate: raw.lastModifiedDate
    )
  }

  private func convertAttendee(_ raw: RawAttendee) -> Attendee {
    Attendee(
      name: raw.name,
      email: raw.email,
      status: attendeeStatus(from: raw.status),
      role: attendeeRole(from: raw.role),
      isCurrentUser: raw.isCurrentUser
    )
  }

  private func convertOrganizer(_ raw: RawOrganizer?) -> Organizer? {
    guard let raw else { return nil }
    return Organizer(name: raw.name, email: raw.email)
  }

  private func attendeeStatus(from rawValue: Int) -> AttendeeStatus {
    switch rawValue {
    case 0: return .unknown
    case 1: return .pending
    case 2: return .accepted
    case 3: return .declined
    case 4: return .tentative
    case 5: return .delegated
    case 6: return .completed
    case 7: return .inProcess
    default: return .unknown
    }
  }

  private func attendeeRole(from rawValue: Int) -> AttendeeRole {
    switch rawValue {
    case 0: return .unknown
    case 1: return .required
    case 2: return .optional
    case 3: return .chair
    case 4: return .nonParticipant
    default: return .unknown
    }
  }

  private func statusString(from status: Int) -> String {
    switch status {
    case 0: return "none"
    case 1: return "confirmed"
    case 2: return "tentative"
    case 3: return "canceled"
    default: return "none"
    }
  }

  private func availabilityString(from availability: Int) -> String {
    switch availability {
    case -1: return "notApplicable"
    case 0: return "busy"
    case 1: return "free"
    case 2: return "tentative"
    case 3: return "unavailable"
    default: return "notApplicable"
    }
  }
}
