import Foundation

public struct RecurrenceInfo: Codable, Equatable, Sendable {
  public let isRecurring: Bool
  public let description: String?

  public init(isRecurring: Bool, description: String? = nil) {
    self.isRecurring = isRecurring
    self.description = description
  }
}

public struct CalendarEvent: Codable, Equatable, Sendable {
  public let id: String
  public let title: String
  public let startDate: Date
  public let endDate: Date
  public let isAllDay: Bool
  public let location: String?
  public let notes: String?
  public let url: String?
  public let meetingUrl: String?
  public let calendar: CalendarInfo
  public let attendees: [Attendee]
  public let organizer: Organizer?
  public let recurrence: RecurrenceInfo
  public let status: String
  public let availability: String
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
    meetingUrl: String? = nil,
    calendar: CalendarInfo,
    attendees: [Attendee] = [],
    organizer: Organizer? = nil,
    recurrence: RecurrenceInfo = RecurrenceInfo(isRecurring: false),
    status: String,
    availability: String = "notApplicable",
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
    self.meetingUrl = meetingUrl
    self.calendar = calendar
    self.attendees = attendees
    self.organizer = organizer
    self.recurrence = recurrence
    self.status = status
    self.availability = availability
    self.timeZone = timeZone
    self.creationDate = creationDate
    self.lastModifiedDate = lastModifiedDate
  }
}
