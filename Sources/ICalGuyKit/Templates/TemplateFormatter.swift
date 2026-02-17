import Foundation
import Mustache

/// Renders events using Mustache templates for text output.
public struct TemplateFormatter: OutputFormatter, Sendable {
  private let options: TextFormatterOptions
  private let colorizer: ANSIColorizer?
  private let grouping: GroupingContext
  private let eventTemplate: MustacheTemplate
  private let dateHeaderTemplate: MustacheTemplate
  private let calendarHeaderTemplate: MustacheTemplate
  private let contextBuilder: EventTemplateContext
  private let decorations: TemplateDecorations

  public init(
    options: TextFormatterOptions = TextFormatterOptions(),
    colorizer: ANSIColorizer? = nil,
    grouping: GroupingContext = GroupingContext(),
    eventTemplate: MustacheTemplate? = nil,
    dateHeaderTemplate: MustacheTemplate? = nil,
    calendarHeaderTemplate: MustacheTemplate? = nil,
    dateFormats: TemplateDateFormats = TemplateDateFormats(),
    truncation: TruncationLimits = TruncationLimits(),
    decorations: TemplateDecorations = TemplateDecorations()
  ) throws {
    self.options = options
    self.colorizer = colorizer
    self.grouping = grouping
    self.eventTemplate =
      try eventTemplate
      ?? MustacheTemplate(
        string: Self.defaultEventTemplate
      )
    self.dateHeaderTemplate =
      try dateHeaderTemplate
      ?? MustacheTemplate(
        string: Self.defaultDateHeaderTemplate
      )
    self.calendarHeaderTemplate =
      try calendarHeaderTemplate
      ?? MustacheTemplate(string: Self.defaultCalendarHeaderTemplate)
    self.contextBuilder = EventTemplateContext(
      formats: dateFormats, truncation: truncation
    )
    self.decorations = decorations
  }

  // MARK: - OutputFormatter

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

  public func formatCalendars(_ calendars: [CalendarInfo]) throws -> String {
    if calendars.isEmpty { return "No calendars." }
    return calendars.map { cal in
      let name = colorizer?.colorize(cal.title, hexColor: cal.color) ?? cal.title
      return "\(name) (\(cal.type), \(cal.source))"
    }.joined(separator: "\n")
  }

  public func formatReminders(_ reminders: [Reminder]) throws -> String {
    if reminders.isEmpty { return "No reminders." }
    if grouping.mode == .calendar {
      return formatRemindersByList(reminders)
    }
    return reminders.map { formatReminder($0) }.joined(separator: "\n")
  }

  public func formatReminderLists(_ lists: [ReminderListInfo]) throws -> String {
    if lists.isEmpty { return "No reminder lists." }
    return lists.map { list in
      let name = colorizer?.colorize(list.title, hexColor: list.color) ?? list.title
      return "\(name) (\(list.source))"
    }.joined(separator: "\n")
  }

  public func formatBirthdays(_ birthdays: [Birthday]) throws -> String {
    if birthdays.isEmpty { return "No birthdays." }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = contextBuilder.dateFormat
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")

    var lines: [String] = []
    var currentDate: String?
    for birthday in birthdays {
      let dateKey = dateFormatter.string(from: birthday.date)
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

  // MARK: - Event Formatting

  private func formatEventsFlat(_ events: [CalendarEvent]) -> String {
    if events.isEmpty { return "No events." }
    let sep = decorations.separator.isEmpty ? "\n" : "\n\(decorations.separator)\n"
    return events.map { renderEvent($0) }.joined(separator: sep)
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
      lines.append(renderDateHeader(group.date))

      if group.events.isEmpty {
        lines.append("  \(dim("No events."))")
      } else {
        let sep = decorations.separator.isEmpty ? "\n" : "\n\(decorations.separator)\n"
        lines.append(
          group.events.map { renderEvent($0) }.joined(separator: sep)
        )
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
      lines.append(renderCalendarHeader(group.calendar))

      let sep = decorations.separator.isEmpty ? "\n" : "\n\(decorations.separator)\n"
      lines.append(
        group.events.map { renderEvent($0) }.joined(separator: sep)
      )
    }

    return lines.joined(separator: "\n")
  }

  // MARK: - Template Rendering

  private func renderDateHeader(_ isoDate: String) -> String {
    let formattedDate = Self.formatISODate(isoDate, format: contextBuilder.dateFormat)
    var context: [String: Any] = ["formattedDate": formattedDate]
    context["bold"] = MustacheLambda { text in
      self.colorizer?.bold(text) ?? text
    }
    let result = dateHeaderTemplate.render(context)
    return Self.trimTrailingWhitespace(result)
  }

  private func renderCalendarHeader(_ calendar: CalendarInfo) -> String {
    var context: [String: Any] = [
      "title": calendar.title,
      "color": calendar.color,
      "type": calendar.type,
      "source": calendar.source,
    ]
    context["bold"] = MustacheLambda { text in
      self.colorizer?.bold(text) ?? text
    }
    context["calendarColor"] = MustacheLambda { text in
      self.colorizer?.colorize(text, hexColor: calendar.color) ?? text
    }
    let result = calendarHeaderTemplate.render(context)
    return Self.trimTrailingWhitespace(result)
  }

  private static func formatISODate(_ isoDate: String, format: String) -> String {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withFullDate]
    if let date = isoFormatter.date(from: isoDate) {
      let df = DateFormatter()
      df.dateFormat = format
      df.locale = Locale(identifier: "en_US_POSIX")
      return df.string(from: date)
    }
    return isoDate
  }

  private func renderEvent(_ event: CalendarEvent) -> String {
    var context = contextBuilder.buildContext(for: event)

    // Inject display toggle flags
    context["showCalendar"] = options.showCalendar
    context["showLocation"] = options.showLocation
    context["showAttendees"] = options.showAttendees
    context["showMeetingUrl"] = options.showMeetingUrl
    context["showNotes"] = options.showNotes
    context["showUid"] = options.showUid

    // Inject decoration variables
    context["bullet"] = decorations.bullet
    context["separator"] = decorations.separator
    context["indent"] = decorations.indent

    // Inject ANSI lambdas
    context["bold"] = MustacheLambda { text in
      self.colorizer?.bold(text) ?? text
    }
    context["dim"] = MustacheLambda { text in
      self.colorizer?.dim(text) ?? text
    }
    context["calendarColor"] = MustacheLambda { text in
      self.colorizer?.colorize(text, hexColor: event.calendar.color) ?? text
    }

    let result = eventTemplate.render(context)
    return Self.trimTrailingWhitespace(result)
  }

  /// Single-pass trim of trailing whitespace and newlines from Mustache output.
  private static func trimTrailingWhitespace(_ string: String) -> String {
    guard let last = string.lastIndex(where: { $0 != "\n" && $0 != " " }) else {
      return ""
    }
    return String(string[...last])
  }

  // MARK: - Reminders (delegated formatting)

  private func formatRemindersByList(_ reminders: [Reminder]) -> String {
    let grouper = EventGrouper()
    let groups = grouper.groupRemindersByList(reminders)

    var lines: [String] = []
    for (index, group) in groups.enumerated() {
      if index > 0 { lines.append("") }
      let header =
        colorizer?.colorize(
          group.list.title, hexColor: group.list.color
        ) ?? group.list.title
      lines.append(colorizer?.bold(header) ?? header)
      for reminder in group.reminders {
        lines.append(formatReminder(reminder))
      }
    }
    return lines.joined(separator: "\n")
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
      let df = DateFormatter()
      df.dateFormat = "MMM d, yyyy"
      df.locale = Locale(identifier: "en_US_POSIX")
      parts.append(dim("due: \(df.string(from: dueDate))"))
    }
    if reminder.priority != .none {
      parts.append(dim("!\(reminder.priority.rawValue)"))
    }
    return parts.joined(separator: "  ")
  }

  private func dim(_ text: String) -> String {
    colorizer?.dim(text) ?? text
  }
}

// MARK: - Default Templates

extension TemplateFormatter {
  /// Default date group header: bold formatted date.
  static let defaultDateHeaderTemplate = "{{#bold}}{{formattedDate}}{{/bold}}"

  /// Default calendar group header: bold, colored calendar name.
  static let defaultCalendarHeaderTemplate =
    "{{#bold}}{{#calendarColor}}{{title}}{{/calendarColor}}{{/bold}}"

  // Standalone section tags (on their own line) have their lines stripped by Mustache.
  // Uses {{{var}}} triple-stache for unescaped variable output (attendee display strings).
  // Section lambdas ({{#bold}}, {{#dim}}, {{#calendarColor}}) are inherently unescaped.
  // {{bullet}}, {{indent}} are configurable decoration variables.
  static let defaultEventTemplate: String = {
    var parts: [String] = []
    // Main line: bullet prefix, dim time, bold title, colored calendar
    // Uses {{{bullet}}} and {{{indent}}} triple-stache to avoid HTML escaping
    parts.append(
      "{{{bullet}}}  {{#dim}}"
        + "{{#isAllDay}}All day{{/isAllDay}}"
        + "{{^isAllDay}}{{startTime}} - {{endTime}}{{/isAllDay}}"
        + "{{/dim}}  {{#bold}}{{title}}{{/bold}}"
        + "{{#showCalendar}}  {{#calendarColor}}"
        + "[{{calendar.title}}]{{/calendarColor}}{{/showCalendar}}"
    )
    // Location detail line
    parts.append("{{#showLocation}}")
    parts.append("{{#hasLocation}}")
    parts.append("{{{indent}}}{{#dim}}Location:{{/dim}} {{location}}")
    parts.append("{{/hasLocation}}")
    parts.append("{{/showLocation}}")
    // Meeting URL detail line
    parts.append("{{#showMeetingUrl}}")
    parts.append("{{#hasMeetingUrl}}")
    parts.append("{{{indent}}}{{#dim}}Meeting:{{/dim}} {{{meetingUrl}}}")
    parts.append("{{/hasMeetingUrl}}")
    parts.append("{{/showMeetingUrl}}")
    // Attendees section
    parts.append("{{#showAttendees}}")
    parts.append("{{#hasAttendees}}")
    parts.append("{{{indent}}}{{#dim}}Attendees:{{/dim}}")
    parts.append("{{#attendees}}")
    parts.append("{{{indent}}}  - {{{displayString}}}")
    parts.append("{{/attendees}}")
    parts.append("{{/hasAttendees}}")
    parts.append("{{/showAttendees}}")
    // Recurrence detail line
    parts.append("{{#isRecurring}}")
    parts.append("{{{indent}}}{{#dim}}Recurs:{{/dim}} {{recurrence.description}}")
    parts.append("{{/isRecurring}}")
    // UID display (dimmed, at end of event block)
    parts.append("{{#showUid}}")
    parts.append("{{{indent}}}{{#dim}}UID:{{/dim}} {{#dim}}{{id}}{{/dim}}")
    parts.append("{{/showUid}}")
    return parts.joined(separator: "\n")
  }()
}
