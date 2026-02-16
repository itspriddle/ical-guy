import Foundation

// MARK: - Options

public enum ReminderSortField: String, Sendable {
  case dueDate
  case priority
  case title
  case creationDate
}

public struct ReminderServiceOptions: Sendable {
  public let filter: ReminderFilter
  public let startDate: Date?
  public let endDate: Date?
  public let includeLists: [String]?
  public let excludeLists: [String]?
  public let limit: Int?
  public let sortBy: ReminderSortField

  public init(
    filter: ReminderFilter = .incomplete,
    startDate: Date? = nil,
    endDate: Date? = nil,
    includeLists: [String]? = nil,
    excludeLists: [String]? = nil,
    limit: Int? = nil,
    sortBy: ReminderSortField = .dueDate
  ) {
    self.filter = filter
    self.startDate = startDate
    self.endDate = endDate
    self.includeLists = includeLists
    self.excludeLists = excludeLists
    self.limit = limit
    self.sortBy = sortBy
  }
}

// MARK: - Service

public struct ReminderService: Sendable {
  private let store: any ReminderStoreProtocol

  public init(store: any ReminderStoreProtocol) {
    self.store = store
  }

  public func fetchReminders(options: ReminderServiceOptions) async throws -> [Reminder] {
    let query = ReminderQuery(
      filter: options.filter,
      startDate: options.startDate,
      endDate: options.endDate
    )

    var rawReminders = try await store.reminders(matching: query)

    // Filter by included lists
    if let include = options.includeLists, !include.isEmpty {
      let includeSet = Set(include.map { $0.lowercased() })
      rawReminders = rawReminders.filter {
        includeSet.contains($0.calendarTitle.lowercased())
      }
    }

    // Filter by excluded lists
    if let exclude = options.excludeLists, !exclude.isEmpty {
      let excludeSet = Set(exclude.map { $0.lowercased() })
      rawReminders = rawReminders.filter {
        !excludeSet.contains($0.calendarTitle.lowercased())
      }
    }

    // Convert
    var reminders = rawReminders.map { convertToReminder($0) }

    // Sort
    reminders.sort { a, b in
      switch options.sortBy {
      case .dueDate:
        return compareDueDates(a.dueDate, b.dueDate)
      case .priority:
        let ap = prioritySortOrder(a.priority)
        let bp = prioritySortOrder(b.priority)
        if ap != bp { return ap < bp }
        return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
      case .title:
        return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
      case .creationDate:
        return compareOptionalDates(a.creationDate, b.creationDate)
      }
    }

    // Apply limit
    if let limit = options.limit, limit > 0 {
      reminders = Array(reminders.prefix(limit))
    }

    return reminders
  }

  public func fetchReminderLists() throws -> [ReminderListInfo] {
    try store.reminderLists().map { raw in
      ReminderListInfo(
        id: raw.id,
        title: raw.title,
        color: raw.color,
        source: raw.source
      )
    }
  }

  // MARK: - Conversion

  private func convertToReminder(_ raw: RawReminder) -> Reminder {
    Reminder(
      id: raw.id,
      title: raw.title,
      notes: raw.notes,
      url: raw.url,
      isCompleted: raw.isCompleted,
      completionDate: raw.completionDate,
      dueDate: resolveDateComponents(raw.dueDateComponents),
      priority: ReminderPriority(rawPriority: raw.priority),
      list: ReminderListInfo(
        id: raw.calendarId,
        title: raw.calendarTitle,
        color: raw.calendarColor,
        source: raw.calendarSource
      ),
      recurrence: RecurrenceInfo(
        isRecurring: raw.isRecurring,
        description: raw.recurrenceDescription
      ),
      creationDate: raw.creationDate,
      lastModifiedDate: raw.lastModifiedDate
    )
  }

  // MARK: - Date Resolution

  static func resolveDateComponents(_ components: RawDateComponents?) -> Date? {
    guard let components else { return nil }
    guard let year = components.year,
      let month = components.month,
      let day = components.day
    else {
      return nil
    }

    var dc = DateComponents()
    dc.year = year
    dc.month = month
    dc.day = day
    dc.hour = components.hour
    dc.minute = components.minute

    if let tzId = components.timeZone {
      dc.timeZone = TimeZone(identifier: tzId)
    }

    return Calendar.current.date(from: dc)
  }

  private func resolveDateComponents(_ components: RawDateComponents?) -> Date? {
    Self.resolveDateComponents(components)
  }

  // MARK: - Sort Helpers

  /// Sort order: high=1, medium=2, low=3, none=4
  private func prioritySortOrder(_ priority: ReminderPriority) -> Int {
    switch priority {
    case .high: return 1
    case .medium: return 2
    case .low: return 3
    case .none: return 4
    }
  }

  /// Nil due dates sort after non-nil. Among non-nil, earlier dates first.
  private func compareDueDates(_ a: Date?, _ b: Date?) -> Bool {
    switch (a, b) {
    case (let a?, let b?): return a < b
    case (_?, nil): return true
    case (nil, _?): return false
    case (nil, nil): return false
    }
  }

  private func compareOptionalDates(_ a: Date?, _ b: Date?) -> Bool {
    switch (a, b) {
    case (let a?, let b?): return a < b
    case (_?, nil): return true
    case (nil, _?): return false
    case (nil, nil): return false
    }
  }
}
