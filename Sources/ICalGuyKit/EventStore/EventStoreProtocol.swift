import Foundation

public struct EventQuery: Sendable {
  public let startDate: Date
  public let endDate: Date
  public let calendars: [String]?

  public init(startDate: Date, endDate: Date, calendars: [String]? = nil) {
    self.startDate = startDate
    self.endDate = endDate
    self.calendars = calendars
  }
}

// MARK: - Raw Attendee/Organizer DTOs

public struct RawAttendee: Sendable {
  public let name: String?
  public let email: String?
  public let status: Int
  public let role: Int
  public let isCurrentUser: Bool

  public init(name: String?, email: String?, status: Int, role: Int, isCurrentUser: Bool) {
    self.name = name
    self.email = email
    self.status = status
    self.role = role
    self.isCurrentUser = isCurrentUser
  }
}

public struct RawOrganizer: Sendable {
  public let name: String?
  public let email: String?

  public init(name: String?, email: String?) {
    self.name = name
    self.email = email
  }
}

// MARK: - Raw Event

public struct RawEvent: Sendable {
  public let id: String
  public let title: String
  public let startDate: Date
  public let endDate: Date
  public let isAllDay: Bool
  public let location: String?
  public let notes: String?
  public let url: String?
  public let calendarId: String
  public let calendarTitle: String
  public let calendarType: String
  public let calendarSource: String
  public let calendarColor: String
  public let attendees: [RawAttendee]
  public let organizer: RawOrganizer?
  public let isRecurring: Bool
  public let recurrenceDescription: String?
  public let status: Int
  public let availability: Int
  public let timeZone: String?
  public let creationDate: Date?
  public let lastModifiedDate: Date?

  public init(
    id: String,
    title: String,
    startDate: Date,
    endDate: Date,
    isAllDay: Bool,
    location: String?,
    notes: String?,
    url: String?,
    calendarId: String,
    calendarTitle: String,
    calendarType: String,
    calendarSource: String,
    calendarColor: String,
    attendees: [RawAttendee] = [],
    organizer: RawOrganizer? = nil,
    isRecurring: Bool = false,
    recurrenceDescription: String? = nil,
    status: Int = 1,
    availability: Int = 0,
    timeZone: String? = nil,
    creationDate: Date? = nil,
    lastModifiedDate: Date? = nil
  ) {
    self.id = id
    self.title = title
    self.startDate = startDate
    self.endDate = endDate
    self.isAllDay = isAllDay
    self.location = location
    self.notes = notes
    self.url = url
    self.calendarId = calendarId
    self.calendarTitle = calendarTitle
    self.calendarType = calendarType
    self.calendarSource = calendarSource
    self.calendarColor = calendarColor
    self.attendees = attendees
    self.organizer = organizer
    self.isRecurring = isRecurring
    self.recurrenceDescription = recurrenceDescription
    self.status = status
    self.availability = availability
    self.timeZone = timeZone
    self.creationDate = creationDate
    self.lastModifiedDate = lastModifiedDate
  }
}

// MARK: - Raw Calendar

public struct RawCalendar: Sendable {
  public let id: String
  public let title: String
  public let type: String
  public let source: String
  public let color: String

  public init(id: String, title: String, type: String, source: String, color: String) {
    self.id = id
    self.title = title
    self.type = type
    self.source = source
    self.color = color
  }
}

// MARK: - Errors

public enum EventStoreError: Error, LocalizedError {
  case accessDenied
  case accessRestricted
  case queryFailed(String)

  public var errorDescription: String? {
    switch self {
    case .accessDenied:
      return """
        Calendar access denied. Grant access in:
        System Settings > Privacy & Security > Calendars
        """
    case .accessRestricted:
      return "Calendar access is restricted by a system policy."
    case .queryFailed(let message):
      return "Event query failed: \(message)"
    }
  }
}

// MARK: - Protocol

public protocol EventStoreProtocol: Sendable {
  func requestAccess() async throws
  func calendars() throws -> [RawCalendar]
  func events(matching query: EventQuery) throws -> [RawEvent]
}
