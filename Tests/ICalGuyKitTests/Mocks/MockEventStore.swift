import Foundation

@testable import ICalGuyKit

final class MockEventStore: EventStoreProtocol, @unchecked Sendable {
  var accessGranted = true
  var mockCalendars: [RawCalendar] = []
  var mockEvents: [RawEvent] = []
  var requestAccessCalled = false

  func requestAccess() async throws {
    requestAccessCalled = true
    if !accessGranted {
      throw EventStoreError.accessDenied
    }
  }

  func calendars() throws -> [RawCalendar] {
    mockCalendars
  }

  func events(matching query: EventQuery) throws -> [RawEvent] {
    // Mimic EventKit behavior: return events that overlap the query range
    mockEvents.filter { event in
      event.startDate < query.endDate && event.endDate > query.startDate
    }
  }
}

// MARK: - Test Data Helpers

extension MockEventStore {
  static func sampleCalendar(
    id: String = "cal-1",
    title: String = "Work",
    type: String = "calDAV",
    source: String = "iCloud",
    color: String = "#1BADF8"
  ) -> RawCalendar {
    RawCalendar(id: id, title: title, type: type, source: source, color: color)
  }

  static func sampleEvent(
    id: String = "evt-1",
    title: String = "Meeting",
    startDate: Date,
    endDate: Date,
    isAllDay: Bool = false,
    location: String? = nil,
    notes: String? = nil,
    url: String? = nil,
    calendarId: String = "cal-1",
    calendarTitle: String = "Work",
    calendarType: String = "calDAV",
    calendarSource: String = "iCloud",
    calendarColor: String = "#1BADF8",
    attendees: [RawAttendee] = [],
    organizer: RawOrganizer? = nil,
    isRecurring: Bool = false,
    recurrenceDescription: String? = nil,
    status: Int = 1,
    availability: Int = 0,
    timeZone: String? = nil,
    creationDate: Date? = nil,
    lastModifiedDate: Date? = nil
  ) -> RawEvent {
    RawEvent(
      id: id,
      title: title,
      startDate: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      location: location,
      notes: notes,
      url: url,
      calendarId: calendarId,
      calendarTitle: calendarTitle,
      calendarType: calendarType,
      calendarSource: calendarSource,
      calendarColor: calendarColor,
      attendees: attendees,
      organizer: organizer,
      isRecurring: isRecurring,
      recurrenceDescription: recurrenceDescription,
      status: status,
      availability: availability,
      timeZone: timeZone,
      creationDate: creationDate,
      lastModifiedDate: lastModifiedDate
    )
  }

  static func sampleAttendee(
    name: String? = "Test User",
    email: String? = "test@example.com",
    status: Int = 2,
    role: Int = 1,
    isCurrentUser: Bool = false
  ) -> RawAttendee {
    RawAttendee(name: name, email: email, status: status, role: role, isCurrentUser: isCurrentUser)
  }

  static func sampleOrganizer(
    name: String? = "Organizer",
    email: String? = "organizer@example.com"
  ) -> RawOrganizer {
    RawOrganizer(name: name, email: email)
  }
}
