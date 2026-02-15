import EventKit
import Foundation

public final class LiveEventStore: EventStoreProtocol, @unchecked Sendable {
  private let store = EKEventStore()
  private let recurrenceDescriber = RecurrenceDescriber()

  public init() {}

  public func requestAccess() async throws {
    let granted = try await store.requestFullAccessToEvents()
    if !granted {
      throw EventStoreError.accessDenied
    }
  }

  public func calendars() throws -> [RawCalendar] {
    store.calendars(for: .event).map { cal in
      RawCalendar(
        id: cal.calendarIdentifier,
        title: cal.title,
        type: calendarTypeString(cal.type),
        source: cal.source.title,
        color: hexColor(from: cal.cgColor)
      )
    }
  }

  public func events(matching query: EventQuery) throws -> [RawEvent] {
    let ekCalendars: [EKCalendar]?
    if let calendarTitles = query.calendars {
      let titleSet = Set(calendarTitles.map { $0.lowercased() })
      ekCalendars = store.calendars(for: .event).filter {
        titleSet.contains($0.title.lowercased())
      }
    } else {
      ekCalendars = nil
    }

    let predicate = store.predicateForEvents(
      withStart: query.startDate,
      end: query.endDate,
      calendars: ekCalendars
    )

    return store.events(matching: predicate).map { event in
      RawEvent(
        id: event.eventIdentifier,
        title: event.title ?? "",
        startDate: event.startDate,
        endDate: event.endDate,
        isAllDay: event.isAllDay,
        location: event.location,
        notes: event.notes,
        url: event.url?.absoluteString,
        calendarId: event.calendar.calendarIdentifier,
        calendarTitle: event.calendar.title,
        calendarType: calendarTypeString(event.calendar.type),
        calendarSource: event.calendar.source.title,
        calendarColor: hexColor(from: event.calendar.cgColor),
        attendees: (event.attendees ?? []).map { buildRawAttendee(from: $0) },
        organizer: buildRawOrganizer(from: event.organizer),
        isRecurring: event.hasRecurrenceRules,
        recurrenceDescription: buildRecurrenceDescription(from: event.recurrenceRules),
        status: event.status.rawValue,
        availability: event.availability.rawValue,
        timeZone: event.timeZone?.identifier,
        creationDate: event.creationDate,
        lastModifiedDate: event.lastModifiedDate
      )
    }
  }

  // MARK: - Attendee/Organizer Extraction

  private func buildRawAttendee(from participant: EKParticipant) -> RawAttendee {
    RawAttendee(
      name: participant.name,
      email: extractEmail(from: participant),
      status: participant.participantStatus.rawValue,
      role: participant.participantRole.rawValue,
      isCurrentUser: participant.isCurrentUser
    )
  }

  private func buildRawOrganizer(from participant: EKParticipant?) -> RawOrganizer? {
    guard let participant else { return nil }
    return RawOrganizer(
      name: participant.name,
      email: extractEmail(from: participant)
    )
  }

  private func extractEmail(from participant: EKParticipant) -> String? {
    let urlString = participant.url.absoluteString
    if urlString.lowercased().hasPrefix("mailto:") {
      return String(urlString.dropFirst(7))
    }
    return nil
  }

  // MARK: - Recurrence

  private func buildRecurrenceDescription(from rules: [EKRecurrenceRule]?) -> String? {
    guard let rules, let rule = rules.first else { return nil }
    let components = RecurrenceDescriber.RuleComponents(
      frequency: rule.frequency.rawValue,
      interval: rule.interval,
      daysOfTheWeek: rule.daysOfTheWeek?.map { ($0.dayOfTheWeek.rawValue, $0.weekNumber) },
      daysOfTheMonth: rule.daysOfTheMonth?.map { $0.intValue },
      monthsOfTheYear: rule.monthsOfTheYear?.map { $0.intValue }
    )
    return recurrenceDescriber.describe(components)
  }

  // MARK: - Calendar Helpers

  private func calendarTypeString(_ type: EKCalendarType) -> String {
    switch type {
    case .local: return "local"
    case .calDAV: return "calDAV"
    case .exchange: return "exchange"
    case .subscription: return "subscription"
    case .birthday: return "birthday"
    @unknown default: return "unknown"
    }
  }

  private func hexColor(from cgColor: CGColor?) -> String {
    guard let color = cgColor,
      let components = color.components,
      components.count >= 3
    else {
      return "#000000"
    }
    let r = Int(components[0] * 255)
    let g = Int(components[1] * 255)
    let b = Int(components[2] * 255)
    return String(format: "#%02X%02X%02X", r, g, b)
  }
}
