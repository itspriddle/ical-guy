import Foundation

/// Configuration for date/time formatting in template contexts.
public struct TemplateDateFormats: Sendable {
  public let timeFormat: String
  public let dateFormat: String

  public init(
    timeFormat: String = "h:mm a",
    dateFormat: String = "EEEE, MMM d, yyyy"
  ) {
    self.timeFormat = timeFormat
    self.dateFormat = dateFormat
  }
}

/// Configuration for field truncation limits.
public struct TruncationLimits: Sendable, Equatable {
  public let notes: Int?
  public let location: Int?

  public init(notes: Int? = nil, location: Int? = nil) {
    self.notes = notes
    self.location = location
  }

  /// Truncates a string to the given limit, appending "..." if truncated.
  /// The ellipsis counts toward the limit. Returns the original string
  /// if limit is nil, 0, or greater than the string length.
  static func truncate(_ text: String, limit: Int?) -> String {
    guard let limit, limit > 0, text.count > limit else { return text }
    if limit <= 3 {
      return String(repeating: ".", count: limit)
    }
    return String(text.prefix(limit - 3)) + "..."
  }
}

/// Configuration for custom bullets, separators, and indentation.
public struct TemplateDecorations: Sendable, Equatable {
  public let bullet: String
  public let separator: String
  public let indent: String

  public init(
    bullet: String = "",
    separator: String = "",
    indent: String = "    "
  ) {
    self.bullet = bullet
    self.separator = separator
    self.indent = indent
  }
}

/// Builds a Mustache-compatible template context dictionary from a `CalendarEvent`.
///
/// All scalar fields, boolean convenience flags, nested objects (calendar, organizer,
/// recurrence), attendees array, and pre-formatted date strings are included.
public struct EventTemplateContext: Sendable {
  private let formats: TemplateDateFormats
  private let truncation: TruncationLimits
  private let referenceDate: @Sendable () -> Date

  /// The configured date format string, used by TemplateFormatter for date group headers.
  var dateFormat: String { formats.dateFormat }

  public init(
    formats: TemplateDateFormats = TemplateDateFormats(),
    truncation: TruncationLimits = TruncationLimits(),
    referenceDate: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.formats = formats
    self.truncation = truncation
    self.referenceDate = referenceDate
  }

  /// Converts a `CalendarEvent` into a `[String: Any]` dictionary suitable for
  /// Mustache template rendering.
  public func buildContext(for event: CalendarEvent) -> [String: Any] {
    var context: [String: Any] = [:]

    // Scalar fields (with optional truncation)
    context["title"] = event.title
    context["location"] = TruncationLimits.truncate(
      event.location ?? "", limit: truncation.location
    )
    context["notes"] = TruncationLimits.truncate(
      event.notes ?? "", limit: truncation.notes
    )
    context["url"] = event.url ?? ""
    context["meetingUrl"] = event.meetingUrl ?? ""
    context["status"] = event.status
    context["availability"] = event.availability
    context["timeZone"] = event.timeZone ?? ""
    context["id"] = event.id

    // Boolean convenience flags
    context["hasLocation"] = event.location != nil && !event.location!.isEmpty
    context["hasNotes"] = event.notes != nil && !event.notes!.isEmpty
    context["hasUrl"] = event.url != nil && !event.url!.isEmpty
    context["hasMeetingUrl"] = event.meetingUrl != nil && !event.meetingUrl!.isEmpty
    context["hasAttendees"] = !event.attendees.isEmpty
    context["hasOrganizer"] = event.organizer != nil
    context["isAllDay"] = event.isAllDay
    context["isRecurring"] = event.recurrence.isRecurring

    // Nested: calendar
    context["calendar"] =
      [
        "title": event.calendar.title,
        "color": event.calendar.color,
        "type": event.calendar.type,
        "source": event.calendar.source,
      ] as [String: Any]

    // Nested: organizer
    if let organizer = event.organizer {
      context["organizer"] =
        [
          "name": organizer.name ?? "",
          "email": organizer.email ?? "",
        ] as [String: Any]
    }

    // Nested: recurrence
    context["recurrence"] =
      [
        "isRecurring": event.recurrence.isRecurring,
        "description": event.recurrence.description ?? "",
      ] as [String: Any]

    // Attendees array
    context["attendees"] = event.attendees.map { attendee in
      var entry: [String: Any] = [
        "name": attendee.name ?? "",
        "email": attendee.email ?? "",
        "status": attendee.status.rawValue,
        "role": attendee.role.rawValue,
        "isCurrentUser": attendee.isCurrentUser,
      ]
      entry["displayString"] = Self.formatAttendeeDisplay(attendee)
      return entry
    }

    addDateFields(to: &context, for: event)

    return context
  }

  private func addDateFields(to context: inout [String: Any], for event: CalendarEvent) {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = formats.timeFormat
    timeFormatter.locale = Locale(identifier: "en_US_POSIX")

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = formats.dateFormat
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")

    if event.isAllDay {
      context["startTime"] = "All day"
      context["endTime"] = "All day"
      context["relativeStart"] = "all day"
      context["relativeEnd"] = "all day"
    } else {
      context["startTime"] = timeFormatter.string(from: event.startDate)
      context["endTime"] = timeFormatter.string(from: event.endDate)
      let now = referenceDate()
      context["relativeStart"] = Self.formatRelativeTime(from: now, to: event.startDate)
      context["relativeEnd"] = Self.formatRelativeTime(from: now, to: event.endDate)
    }

    context["startDate"] = dateFormatter.string(from: event.startDate)
    context["endDate"] = dateFormatter.string(from: event.endDate)
  }

  /// Formats the time interval between two dates as natural language.
  ///
  /// Examples: "now", "in 30 minutes", "in 2 hours", "1 hour ago", "in 3 days"
  static func formatRelativeTime(from now: Date, to target: Date) -> String {
    let seconds = target.timeIntervalSince(now)
    let absSeconds = abs(seconds)

    // Within 1 minute → "now"
    if absSeconds < 60 {
      return "now"
    }

    let description = formatDuration(absSeconds)
    return seconds > 0 ? "in \(description)" : "\(description) ago"
  }

  private static func formatDuration(_ absSeconds: TimeInterval) -> String {
    let totalMinutes = Int(absSeconds / 60)

    // Less than 1 hour → minutes only
    if totalMinutes < 60 {
      return totalMinutes == 1 ? "1 minute" : "\(totalMinutes) minutes"
    }

    let hours = totalMinutes / 60
    let remainingMinutes = totalMinutes % 60

    // Less than 24 hours → hours (+ minutes if non-zero)
    if hours < 24 {
      let hourStr = hours == 1 ? "1 hour" : "\(hours) hours"
      if remainingMinutes == 0 {
        return hourStr
      }
      let minStr = remainingMinutes == 1 ? "1 minute" : "\(remainingMinutes) minutes"
      return "\(hourStr) \(minStr)"
    }

    // 24 hours or more → days
    let days = hours / 24
    return days == 1 ? "1 day" : "\(days) days"
  }

  /// Formats an attendee for display: "Name <email> (status)".
  private static func formatAttendeeDisplay(_ attendee: Attendee) -> String {
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
}
