import Foundation

// MARK: - Query

public enum ReminderFilter: Sendable {
  case incomplete
  case completed
  case all
}

public struct ReminderQuery: Sendable {
  public let filter: ReminderFilter
  public let startDate: Date?
  public let endDate: Date?
  public let calendars: [String]?

  public init(
    filter: ReminderFilter = .incomplete,
    startDate: Date? = nil,
    endDate: Date? = nil,
    calendars: [String]? = nil
  ) {
    self.filter = filter
    self.startDate = startDate
    self.endDate = endDate
    self.calendars = calendars
  }
}

// MARK: - Raw DateComponents

public struct RawDateComponents: Sendable {
  public let year: Int?
  public let month: Int?
  public let day: Int?
  public let hour: Int?
  public let minute: Int?
  public let timeZone: String?

  public init(
    year: Int? = nil,
    month: Int? = nil,
    day: Int? = nil,
    hour: Int? = nil,
    minute: Int? = nil,
    timeZone: String? = nil
  ) {
    self.year = year
    self.month = month
    self.day = day
    self.hour = hour
    self.minute = minute
    self.timeZone = timeZone
  }
}

// MARK: - Raw Reminder

public struct RawReminder: Sendable {
  public let id: String
  public let title: String
  public let notes: String?
  public let url: String?
  public let isCompleted: Bool
  public let completionDate: Date?
  public let dueDateComponents: RawDateComponents?
  public let priority: Int
  public let calendarId: String
  public let calendarTitle: String
  public let calendarColor: String
  public let calendarSource: String
  public let isRecurring: Bool
  public let recurrenceDescription: String?
  public let creationDate: Date?
  public let lastModifiedDate: Date?

  public init(
    id: String,
    title: String,
    notes: String? = nil,
    url: String? = nil,
    isCompleted: Bool = false,
    completionDate: Date? = nil,
    dueDateComponents: RawDateComponents? = nil,
    priority: Int = 0,
    calendarId: String = "",
    calendarTitle: String = "",
    calendarColor: String = "#000000",
    calendarSource: String = "",
    isRecurring: Bool = false,
    recurrenceDescription: String? = nil,
    creationDate: Date? = nil,
    lastModifiedDate: Date? = nil
  ) {
    self.id = id
    self.title = title
    self.notes = notes
    self.url = url
    self.isCompleted = isCompleted
    self.completionDate = completionDate
    self.dueDateComponents = dueDateComponents
    self.priority = priority
    self.calendarId = calendarId
    self.calendarTitle = calendarTitle
    self.calendarColor = calendarColor
    self.calendarSource = calendarSource
    self.isRecurring = isRecurring
    self.recurrenceDescription = recurrenceDescription
    self.creationDate = creationDate
    self.lastModifiedDate = lastModifiedDate
  }
}

// MARK: - Raw Reminder List

public struct RawReminderList: Sendable {
  public let id: String
  public let title: String
  public let color: String
  public let source: String

  public init(id: String, title: String, color: String, source: String) {
    self.id = id
    self.title = title
    self.color = color
    self.source = source
  }
}

// MARK: - Errors

public enum ReminderStoreError: Error, LocalizedError {
  case accessDenied
  case accessRestricted
  case queryFailed(String)

  public var errorDescription: String? {
    switch self {
    case .accessDenied:
      return """
        Reminders access denied. Grant access in:
        System Settings > Privacy & Security > Reminders
        """
    case .accessRestricted:
      return "Reminders access is restricted by a system policy."
    case .queryFailed(let message):
      return "Reminder query failed: \(message)"
    }
  }
}

// MARK: - Protocol

public protocol ReminderStoreProtocol: Sendable {
  func requestAccess() async throws
  func reminderLists() throws -> [RawReminderList]
  func reminders(matching query: ReminderQuery) async throws -> [RawReminder]
}
