import Foundation

public struct FreeTimeFormatter: Sendable {
  private let colorizer: ANSIColorizer?
  private let timeFormatter: DateFormatter

  public init(colorizer: ANSIColorizer? = nil) {
    self.colorizer = colorizer

    let tf = DateFormatter()
    tf.dateFormat = "h:mm a"
    tf.locale = Locale(identifier: "en_US_POSIX")
    self.timeFormatter = tf
  }

  public func format(_ result: FreeTimeResult, asJSON: Bool) throws -> String {
    if asJSON {
      return try encodeJSON(result)
    }
    return formatText(result)
  }

  // MARK: - JSON

  private func encodeJSON(_ result: FreeTimeResult) throws -> String {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(result)
    return String(data: data, encoding: .utf8)!
  }

  // MARK: - Text

  private func formatText(_ result: FreeTimeResult) -> String {
    if result.days.allSatisfy({ $0.slots.isEmpty }) {
      return "No free time found."
    }

    var lines: [String] = []

    for day in result.days {
      let total = formatDuration(day.totalFreeMinutes)
      let header = "\(day.dateLabel)  (\(total) free)"
      lines.append(colorizer?.bold(header) ?? header)

      if day.slots.isEmpty {
        lines.append("  No free slots")
      } else {
        for slot in day.slots {
          let start = timeFormatter.string(from: slot.start)
          let end = timeFormatter.string(from: slot.end)
          let duration = formatDuration(slot.durationMinutes)
          let tierLabel = tierDisplayLabel(slot.tier)
          let styledTier = styleTier(tierLabel, tier: slot.tier)
          lines.append("  \(dim("\(start) - \(end)"))  \(duration)  \(styledTier)")
        }
      }

      lines.append("")
    }

    // Summary
    let totalDuration = formatDuration(result.totalFreeMinutes)
    let dayCount = result.days.count
    let dayNoun = dayCount == 1 ? "day" : "days"
    lines.append("Summary: \(totalDuration) free across \(dayCount) \(dayNoun)")

    let whStart = formatWorkTime(
      hour: result.workingHours.startHour,
      minute: result.workingHours.startMinute
    )
    let whEnd = formatWorkTime(
      hour: result.workingHours.endHour,
      minute: result.workingHours.endMinute
    )
    lines.append(
      "Working hours: \(whStart) - \(whEnd), "
        + "minimum slot: \(result.minDurationMinutes) minutes"
    )

    return lines.joined(separator: "\n")
  }

  private func tierDisplayLabel(_ tier: DurationTier) -> String {
    switch tier {
    case .deep: return "[deep work]"
    case .focus: return "[focus]"
    case .short: return "[short]"
    case .brief: return "[brief]"
    }
  }

  private func styleTier(_ label: String, tier: DurationTier) -> String {
    guard let colorizer else { return label }
    switch tier {
    case .deep: return colorizer.colorize(label, hexColor: "#34C759")
    case .focus: return colorizer.colorize(label, hexColor: "#007AFF")
    case .short: return colorizer.colorize(label, hexColor: "#FF9500")
    case .brief: return colorizer.colorize(label, hexColor: "#FF3B30")
    }
  }

  private func formatDuration(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    if hours == 0 { return "\(mins)m" }
    if mins == 0 { return "\(hours)h" }
    return "\(hours)h \(mins)m"
  }

  private func formatWorkTime(hour: Int, minute: Int) -> String {
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    let cal = Calendar(identifier: .gregorian)
    guard let date = cal.date(from: components) else {
      return "\(hour):\(String(format: "%02d", minute))"
    }
    return timeFormatter.string(from: date)
  }

  private func dim(_ text: String) -> String {
    colorizer?.dim(text) ?? text
  }
}
