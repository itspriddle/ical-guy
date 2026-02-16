import Foundation

public struct ConflictFormatter: Sendable {
  private let colorizer: ANSIColorizer?
  private let timeFormatter: DateFormatter
  private let dateHeaderFormatter: DateFormatter

  public init(colorizer: ANSIColorizer? = nil) {
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

  public func format(_ result: ConflictResult, asJSON: Bool) throws -> String {
    if asJSON {
      return try encodeJSON(result)
    }
    return formatText(result)
  }

  // MARK: - JSON

  private func encodeJSON(_ result: ConflictResult) throws -> String {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(result)
    return String(data: data, encoding: .utf8)!
  }

  // MARK: - Text

  private func formatText(_ result: ConflictResult) -> String {
    if result.groups.isEmpty {
      return "No conflicts found."
    }

    var lines: [String] = []
    var currentDate: String?

    for group in result.groups {
      let dateKey = dateHeaderFormatter.string(from: group.windowStart)
      if dateKey != currentDate {
        if currentDate != nil { lines.append("") }
        let header = colorizer?.bold(dateKey) ?? dateKey
        lines.append(header)
        currentDate = dateKey
      }

      let windowStart = timeFormatter.string(from: group.windowStart)
      let windowEnd = timeFormatter.string(from: group.windowEnd)
      let count = group.events.count
      let label = "CONFLICT (\(count) events, \(windowStart) - \(windowEnd))"
      let styledLabel = colorizer?.colorize(label, hexColor: "#FF3B30") ?? label
      let boldLabel = colorizer?.bold(styledLabel) ?? styledLabel
      lines.append("  \(boldLabel)")

      for event in group.events {
        let start = timeFormatter.string(from: event.startDate)
        let end = timeFormatter.string(from: event.endDate)
        let time = dim("\(start) - \(end)")
        let calName = formatCalendar(event.calendar)
        lines.append("    \(time)  \(event.title)  \(calName)")
      }
    }

    lines.append("")
    let noun = result.totalConflicts == 1 ? "conflict" : "conflicts"
    lines.append("Found \(result.totalConflicts) \(noun).")

    return lines.joined(separator: "\n")
  }

  private func formatCalendar(_ cal: CalendarInfo) -> String {
    let label = "[\(cal.title)]"
    return colorizer?.colorize(label, hexColor: cal.color) ?? label
  }

  private func dim(_ text: String) -> String {
    colorizer?.dim(text) ?? text
  }
}
