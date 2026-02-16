import Foundation

@testable import ICalGuyKit

final class MockReminderStore: ReminderStoreProtocol, @unchecked Sendable {
  var accessGranted = true
  var mockReminderLists: [RawReminderList] = []
  var mockReminders: [RawReminder] = []
  var requestAccessCalled = false

  func requestAccess() async throws {
    requestAccessCalled = true
    if !accessGranted {
      throw ReminderStoreError.accessDenied
    }
  }

  func reminderLists() throws -> [RawReminderList] {
    mockReminderLists
  }

  func reminders(matching query: ReminderQuery) async throws -> [RawReminder] {
    var results = mockReminders

    // Filter by completion status
    switch query.filter {
    case .incomplete:
      results = results.filter { !$0.isCompleted }
    case .completed:
      results = results.filter { $0.isCompleted }
    case .all:
      break
    }

    return results
  }
}

// MARK: - Test Data Helpers

extension MockReminderStore {
  static func sampleReminderList(
    id: String = "list-1",
    title: String = "Personal",
    color: String = "#FF9500",
    source: String = "iCloud"
  ) -> RawReminderList {
    RawReminderList(id: id, title: title, color: color, source: source)
  }

  static func sampleReminder(
    id: String = "rem-1",
    title: String = "Buy groceries",
    notes: String? = nil,
    url: String? = nil,
    isCompleted: Bool = false,
    completionDate: Date? = nil,
    dueDateComponents: RawDateComponents? = nil,
    priority: Int = 0,
    calendarId: String = "list-1",
    calendarTitle: String = "Personal",
    calendarColor: String = "#FF9500",
    calendarSource: String = "iCloud",
    isRecurring: Bool = false,
    recurrenceDescription: String? = nil,
    creationDate: Date? = nil,
    lastModifiedDate: Date? = nil
  ) -> RawReminder {
    RawReminder(
      id: id,
      title: title,
      notes: notes,
      url: url,
      isCompleted: isCompleted,
      completionDate: completionDate,
      dueDateComponents: dueDateComponents,
      priority: priority,
      calendarId: calendarId,
      calendarTitle: calendarTitle,
      calendarColor: calendarColor,
      calendarSource: calendarSource,
      isRecurring: isRecurring,
      recurrenceDescription: recurrenceDescription,
      creationDate: creationDate,
      lastModifiedDate: lastModifiedDate
    )
  }
}
