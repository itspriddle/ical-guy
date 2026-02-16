import Foundation

public struct TextFormatterOptions: Sendable {
  public let showCalendar: Bool
  public let showLocation: Bool
  public let showAttendees: Bool
  public let showMeetingUrl: Bool
  public let showNotes: Bool

  public init(
    showCalendar: Bool = true,
    showLocation: Bool = true,
    showAttendees: Bool = true,
    showMeetingUrl: Bool = true,
    showNotes: Bool = false
  ) {
    self.showCalendar = showCalendar
    self.showLocation = showLocation
    self.showAttendees = showAttendees
    self.showMeetingUrl = showMeetingUrl
    self.showNotes = showNotes
  }
}

public struct TextFormatter: OutputFormatter, Sendable {
  private let options: TextFormatterOptions
  private let colorizer: ANSIColorizer?
  private let grouping: GroupingContext
  private let timeFormatter: DateFormatter
  private let dateHeaderFormatter: DateFormatter

  public init(
    options: TextFormatterOptions = TextFormatterOptions(),
    colorizer: ANSIColorizer? = nil,
    grouping: GroupingContext = GroupingContext()
  ) {
    self.options = options
    self.colorizer = colorizer
    self.grouping = grouping

    let tf = DateFormatter()
    tf.dateFormat = "h:mm a"
    tf.locale = Locale(identifier: "en_US_POSIX")
    self.timeFormatter = tf

    let df = DateFormatter()
    df.dateFormat = "EEEE, MMM d, yyyy"
    df.locale = Locale(identifier: "en_US_POSIX")
    self.dateHeaderFormatter = df
  }

  public func formatEvents(_ events: [CalendarEvent]) throws -> String {
    switch grouping.mode {
    case .none:
      return formatEventsFlat(events)
    case .date:
      return formatEventsByDate(events)
    case .calendar:
      return formatEventsByCalendar(events)
    }
  }

  private func formatEventsFlat(_ events: [CalendarEvent]) -> String {
    if events.isEmpty { return "No events." }
    return events.map { formatEvent($0) }.joined(separator: "\n")
  }

  private func formatEventsByDate(_ events: [CalendarEvent]) -> String {
    let grouper = EventGrouper()
    let groups = grouper.groupByDate(
      events,
      from: grouping.dateRange?.from,
      to: grouping.dateRange?.to,
      showEmptyDates: grouping.showEmptyDates
    )

    if groups.isEmpty { return "No events." }
    if groups.allSatisfy({ $0.events.isEmpty }) && !grouping.showEmptyDates {
      return "No events."
    }

    var lines: [String] = []
    for (index, group) in groups.enumerated() {
      if index > 0 { lines.append("") }
      let dateHeader = formatDateGroupHeader(group.date)
      let header = colorizer?.bold(dateHeader) ?? dateHeader
      lines.append(header)

      if group.events.isEmpty {
        lines.append("  \(dim("No events."))")
      } else {
        for event in group.events {
          lines.append(formatEvent(event))
        }
      }
    }

    return lines.joined(separator: "\n")
  }

  private func formatEventsByCalendar(_ events: [CalendarEvent]) -> String {
    if events.isEmpty { return "No events." }

    let grouper = EventGrouper()
    let groups = grouper.groupByCalendar(events)

    var lines: [String] = []
    for (index, group) in groups.enumerated() {
      if index > 0 { lines.append("") }
      let header =
        colorizer?.colorize(group.calendar.title, hexColor: group.calendar.color)
        ?? group.calendar.title
      lines.append(colorizer?.bold(header) ?? header)

      for event in group.events {
        lines.append(formatEvent(event))
      }
    }

    return lines.joined(separator: "\n")
  }

  private func formatDateGroupHeader(_ isoDate: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    if let date = formatter.date(from: isoDate) {
      return dateHeaderFormatter.string(from: date)
    }
    return isoDate
  }

  public func formatCalendars(_ calendars: [CalendarInfo]) throws -> String {
    if calendars.isEmpty { return "No calendars." }

    return calendars.map { cal in
      let name = colorizer?.colorize(cal.title, hexColor: cal.color) ?? cal.title
      return "\(name) (\(cal.type), \(cal.source))"
    }.joined(separator: "\n")
  }

  // MARK: - Reminders

  public func formatReminders(_ reminders: [Reminder]) throws -> String {
    if reminders.isEmpty { return "No reminders." }

    if grouping.mode == .calendar {
      return formatRemindersByList(reminders)
    }
    return reminders.map { formatReminder($0) }.joined(separator: "\n")
  }

  private func formatRemindersByList(_ reminders: [Reminder]) -> String {
    let grouper = EventGrouper()
    let groups = grouper.groupRemindersByList(reminders)

    var lines: [String] = []
    for (index, group) in groups.enumerated() {
      if index > 0 { lines.append("") }
      let header =
        colorizer?.colorize(group.list.title, hexColor: group.list.color)
        ?? group.list.title
      lines.append(colorizer?.bold(header) ?? header)

      for reminder in group.reminders {
        lines.append(formatReminder(reminder))
      }
    }

    return lines.joined(separator: "\n")
  }

  public func formatBirthdays(_ birthdays: [Birthday]) throws -> String {
    if birthdays.isEmpty { return "No birthdays." }

    var lines: [String] = []
    var currentDate: String?

    for birthday in birthdays {
      let dateKey = dateHeaderFormatter.string(from: birthday.date)
      if dateKey != currentDate {
        if currentDate != nil { lines.append("") }
        let header = colorizer?.bold(dateKey) ?? dateKey
        lines.append(header)
        currentDate = dateKey
      }

      lines.append("  \(birthday.name)")
    }

    return lines.joined(separator: "\n")
  }

  public func formatReminderLists(_ lists: [ReminderListInfo]) throws -> String {
    if lists.isEmpty { return "No reminder lists." }

    return lists.map { list in
      let name = colorizer?.colorize(list.title, hexColor: list.color) ?? list.title
      return "\(name) (\(list.source))"
    }.joined(separator: "\n")
  }

  private func formatReminder(_ reminder: Reminder) -> String {
    let checkbox = reminder.isCompleted ? "[x]" : "[ ]"
    let title = colorizer?.bold(reminder.title) ?? reminder.title
    let listName =
      colorizer?.colorize(
        "[\(reminder.list.title)]", hexColor: reminder.list.color
      ) ?? "[\(reminder.list.title)]"

    var parts = ["\(checkbox) \(title)  \(listName)"]

    if let dueDate = reminder.dueDate {
      parts.append(dim("due: \(dueDateFormatter.string(from: dueDate))"))
    }

    if reminder.priority != .none {
      parts.append(dim("!\(reminder.priority.rawValue)"))
    }

    return parts.joined(separator: "  ")
  }

  private var dueDateFormatter: DateFormatter {
    let df = DateFormatter()
    df.dateFormat = "MMM d, yyyy"
    df.locale = Locale(identifier: "en_US_POSIX")
    return df
  }

  // MARK: - Event Formatting

  private func formatEvent(_ event: CalendarEvent) -> String {
    let detail = "    "
    var lines: [String] = []

    // Time + Title + Calendar
    let timeRange = formatTimeRange(event)
    let title = colorizer?.bold(event.title) ?? event.title
    var mainLine = "  \(timeRange)  \(title)"
    if options.showCalendar {
      let calName =
        colorizer?.colorize(
          "[\(event.calendar.title)]", hexColor: event.calendar.color
        ) ?? "[\(event.calendar.title)]"
      mainLine += "  \(calName)"
    }
    lines.append(mainLine)

    if options.showLocation, let location = event.location, !location.isEmpty {
      lines.append("\(detail)\(dim("Location:")) \(location)")
    }

    if options.showMeetingUrl, let meetingUrl = event.meetingUrl {
      lines.append("\(detail)\(dim("Meeting:")) \(meetingUrl)")
    }

    if options.showAttendees, !event.attendees.isEmpty {
      lines.append("\(detail)\(dim("Attendees:"))")
      for attendee in event.attendees {
        lines.append("\(detail)  - \(formatAttendee(attendee))")
      }
    }

    if event.recurrence.isRecurring, let desc = event.recurrence.description {
      lines.append("\(detail)\(dim("Recurs:")) \(desc)")
    }

    return lines.joined(separator: "\n")
  }

  private func formatTimeRange(_ event: CalendarEvent) -> String {
    if event.isAllDay {
      return dim("All day")
    }
    let start = timeFormatter.string(from: event.startDate)
    let end = timeFormatter.string(from: event.endDate)
    return dim("\(start) - \(end)")
  }

  private func formatAttendee(_ attendee: Attendee) -> String {
    let display: String
    if let name = attendee.name, let email = attendee.email, name != email {
      display = "\(name) <\(email)>"
    } else {
      display = attendee.name ?? attendee.email ?? "Unknown"
    }
    if attendee.isCurrentUser {
      return "\(display) (you)"
    }
    let status = attendee.status == .unknown ? "" : " (\(attendee.status.rawValue))"
    return "\(display)\(status)"
  }

  private func dim(_ text: String) -> String {
    colorizer?.dim(text) ?? text
  }
}
