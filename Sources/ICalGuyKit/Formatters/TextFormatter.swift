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
  private let timeFormatter: DateFormatter
  private let dateHeaderFormatter: DateFormatter

  public init(
    options: TextFormatterOptions = TextFormatterOptions(), colorizer: ANSIColorizer? = nil
  ) {
    self.options = options
    self.colorizer = colorizer

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
    if events.isEmpty { return "No events." }

    var lines: [String] = []
    var currentDate: String?

    for event in events {
      let dateKey = dateHeaderFormatter.string(from: event.startDate)
      if dateKey != currentDate {
        if currentDate != nil { lines.append("") }
        let header = colorizer?.bold(dateKey) ?? dateKey
        lines.append(header)
        currentDate = dateKey
      }

      lines.append(formatEvent(event))
    }

    return lines.joined(separator: "\n")
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

    return reminders.map { formatReminder($0) }.joined(separator: "\n")
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
