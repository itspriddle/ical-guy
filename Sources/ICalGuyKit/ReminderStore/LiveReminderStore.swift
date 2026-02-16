import EventKit
import Foundation

public final class LiveReminderStore: ReminderStoreProtocol, @unchecked Sendable {
  private let store = EKEventStore()
  private let recurrenceDescriber = RecurrenceDescriber()

  public init() {}

  public func requestAccess() async throws {
    let granted = try await store.requestFullAccessToReminders()
    if !granted {
      throw ReminderStoreError.accessDenied
    }
  }

  public func reminderLists() throws -> [RawReminderList] {
    store.calendars(for: .reminder).map { cal in
      RawReminderList(
        id: cal.calendarIdentifier,
        title: cal.title,
        color: hexColor(from: cal.cgColor),
        source: cal.source.title
      )
    }
  }

  public func reminders(matching query: ReminderQuery) async throws -> [RawReminder] {
    let ekCalendars = resolveCalendars(query.calendars)
    let predicate = buildPredicate(
      filter: query.filter,
      startDate: query.startDate,
      endDate: query.endDate,
      calendars: ekCalendars
    )

    typealias Cont = CheckedContinuation<[RawReminder], Error>
    return try await withCheckedThrowingContinuation { (continuation: Cont) in
      store.fetchReminders(matching: predicate) { [self] reminders in
        if let reminders {
          let raw = reminders.map { self.buildRawReminder(from: $0) }
          continuation.resume(returning: raw)
        } else {
          continuation.resume(
            throwing: ReminderStoreError.queryFailed("Fetch returned nil")
          )
        }
      }
    }
  }

  // MARK: - Predicate Building

  private func buildPredicate(
    filter: ReminderFilter,
    startDate: Date?,
    endDate: Date?,
    calendars: [EKCalendar]?
  ) -> NSPredicate {
    switch filter {
    case .incomplete:
      return store.predicateForIncompleteReminders(
        withDueDateStarting: startDate,
        ending: endDate,
        calendars: calendars
      )
    case .completed:
      return store.predicateForCompletedReminders(
        withCompletionDateStarting: startDate,
        ending: endDate,
        calendars: calendars
      )
    case .all:
      return store.predicateForReminders(in: calendars)
    }
  }

  private func resolveCalendars(_ titles: [String]?) -> [EKCalendar]? {
    guard let titles else { return nil }
    let titleSet = Set(titles.map { $0.lowercased() })
    let matches = store.calendars(for: .reminder).filter {
      titleSet.contains($0.title.lowercased())
    }
    return matches.isEmpty ? nil : matches
  }

  // MARK: - Raw Reminder Building

  private func buildRawReminder(from reminder: EKReminder) -> RawReminder {
    RawReminder(
      id: reminder.calendarItemIdentifier,
      title: reminder.title ?? "",
      notes: reminder.notes,
      url: reminder.url?.absoluteString,
      isCompleted: reminder.isCompleted,
      completionDate: reminder.completionDate,
      dueDateComponents: buildRawDateComponents(from: reminder.dueDateComponents),
      priority: reminder.priority,
      calendarId: reminder.calendar.calendarIdentifier,
      calendarTitle: reminder.calendar.title,
      calendarColor: hexColor(from: reminder.calendar.cgColor),
      calendarSource: reminder.calendar.source.title,
      isRecurring: reminder.hasRecurrenceRules,
      recurrenceDescription: buildRecurrenceDescription(from: reminder.recurrenceRules),
      creationDate: reminder.creationDate,
      lastModifiedDate: reminder.lastModifiedDate
    )
  }

  private func buildRawDateComponents(from dc: DateComponents?) -> RawDateComponents? {
    guard let dc else { return nil }
    return RawDateComponents(
      year: dc.year,
      month: dc.month,
      day: dc.day,
      hour: dc.hour,
      minute: dc.minute,
      timeZone: dc.timeZone?.identifier
    )
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

  // MARK: - Helpers

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
