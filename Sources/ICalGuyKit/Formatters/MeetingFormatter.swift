import Foundation

public struct MeetingContext: Sendable {
  public let event: CalendarEvent
  public let timeRemaining: TimeInterval?
  public let timeUntil: TimeInterval?

  public var isNow: Bool { timeRemaining != nil }
  public var hasMeetingUrl: Bool { event.meetingUrl != nil }

  public init(event: CalendarEvent, timeRemaining: TimeInterval?, timeUntil: TimeInterval?) {
    self.event = event
    self.timeRemaining = timeRemaining
    self.timeUntil = timeUntil
  }
}

public struct MeetingFormatter: Sendable {
  private let colorizer: ANSIColorizer?
  private let timeFormatter: DateFormatter
  private let jsonFormatter: JSONFormatter

  public init(colorizer: ANSIColorizer? = nil) {
    self.colorizer = colorizer

    let tf = DateFormatter()
    tf.dateFormat = "h:mm a"
    tf.locale = Locale(identifier: "en_US_POSIX")
    self.timeFormatter = tf

    self.jsonFormatter = JSONFormatter(pretty: true)
  }

  public func formatMeeting(_ context: MeetingContext, asJSON: Bool) throws -> String {
    if asJSON {
      return try jsonFormatter.formatEvents([context.event])
    }
    return formatMeetingText(context)
  }

  public func formatMeetingList(_ events: [CalendarEvent], asJSON: Bool) throws -> String {
    if asJSON {
      return try jsonFormatter.formatEvents(events)
    }
    return formatMeetingListText(events)
  }

  // MARK: - Text Formatting

  private func formatMeetingText(_ context: MeetingContext) -> String {
    let event = context.event
    var lines: [String] = []

    let title = colorizer?.bold(event.title) ?? event.title
    lines.append(title)

    let start = timeFormatter.string(from: event.startDate)
    let end = timeFormatter.string(from: event.endDate)
    lines.append("  \(dim("Time:"))      \(start) - \(end)")

    if let calColor = colorizer {
      let calName = calColor.colorize(event.calendar.title, hexColor: event.calendar.color)
      lines.append("  \(dim("Calendar:"))  \(calName)")
    } else {
      lines.append("  \(dim("Calendar:"))  \(event.calendar.title)")
    }

    if let meetingUrl = event.meetingUrl {
      lines.append("  \(dim("Meeting:"))   \(meetingUrl)")
    }

    if let location = event.location, !location.isEmpty, event.meetingUrl == nil {
      lines.append("  \(dim("Location:"))  \(location)")
    }

    if !event.attendees.isEmpty {
      let attendeeStr = event.attendees.map { attendee in
        let name = attendee.name ?? attendee.email ?? "Unknown"
        if attendee.isCurrentUser { return "\(name) (you)" }
        return "\(name) (\(attendee.status.rawValue))"
      }.joined(separator: ", ")
      lines.append("  \(dim("Attendees:")) \(attendeeStr)")
    }

    if let remaining = context.timeRemaining {
      lines.append("  \(dim("Ends in:"))   \(formatDuration(remaining))")
    } else if let until = context.timeUntil {
      lines.append("  \(dim("Starts in:")) \(formatDuration(until))")
    }

    return lines.joined(separator: "\n")
  }

  private func formatMeetingListText(_ events: [CalendarEvent]) -> String {
    if events.isEmpty { return "No meetings today." }

    return events.map { event in
      let start = timeFormatter.string(from: event.startDate)
      let end = timeFormatter.string(from: event.endDate)
      let time = dim("\(start) - \(end)")
      let title = colorizer?.bold(event.title) ?? event.title
      let url = event.meetingUrl.map { "  \($0)" } ?? ""
      return "\(time)  \(title)\(url)"
    }.joined(separator: "\n")
  }

  private func formatDuration(_ interval: TimeInterval) -> String {
    let totalMinutes = Int(interval) / 60
    if totalMinutes < 60 {
      return "\(totalMinutes) minute\(totalMinutes == 1 ? "" : "s")"
    }
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if minutes == 0 {
      return "\(hours) hour\(hours == 1 ? "" : "s")"
    }
    return "\(hours)h \(minutes)m"
  }

  private func dim(_ text: String) -> String {
    colorizer?.dim(text) ?? text
  }
}
