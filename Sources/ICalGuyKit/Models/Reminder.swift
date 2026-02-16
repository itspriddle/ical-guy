import Foundation

// MARK: - Priority

public enum ReminderPriority: String, Codable, Sendable {
  case none
  case low
  case medium
  case high

  /// Map from EKReminder priority (0-9) to semantic priority.
  /// 0 = none, 1-4 = high, 5 = medium, 6-9 = low
  public init(rawPriority: Int) {
    switch rawPriority {
    case 1...4: self = .high
    case 5: self = .medium
    case 6...9: self = .low
    default: self = .none
    }
  }
}

// MARK: - Reminder List Info

public struct ReminderListInfo: Codable, Equatable, Sendable {
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

// MARK: - Reminder

public struct Reminder: Codable, Equatable, Sendable {
  public let id: String
  public let title: String
  public let notes: String?
  public let url: String?
  public let isCompleted: Bool
  public let completionDate: Date?
  public let dueDate: Date?
  public let priority: ReminderPriority
  public let list: ReminderListInfo
  public let recurrence: RecurrenceInfo
  public let creationDate: Date?
  public let lastModifiedDate: Date?

  public init(
    id: String,
    title: String,
    notes: String? = nil,
    url: String? = nil,
    isCompleted: Bool = false,
    completionDate: Date? = nil,
    dueDate: Date? = nil,
    priority: ReminderPriority = .none,
    list: ReminderListInfo,
    recurrence: RecurrenceInfo = RecurrenceInfo(isRecurring: false),
    creationDate: Date? = nil,
    lastModifiedDate: Date? = nil
  ) {
    self.id = id
    self.title = title
    self.notes = notes
    self.url = url
    self.isCompleted = isCompleted
    self.completionDate = completionDate
    self.dueDate = dueDate
    self.priority = priority
    self.list = list
    self.recurrence = recurrence
    self.creationDate = creationDate
    self.lastModifiedDate = lastModifiedDate
  }
}
