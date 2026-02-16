import Foundation

public enum OutputFormat: String, Sendable, CaseIterable {
  case json
  case text
}

public protocol OutputFormatter: Sendable {
  func formatEvents(_ events: [CalendarEvent]) throws -> String
  func formatCalendars(_ calendars: [CalendarInfo]) throws -> String
  func formatReminders(_ reminders: [Reminder]) throws -> String
  func formatReminderLists(_ lists: [ReminderListInfo]) throws -> String
  func formatBirthdays(_ birthdays: [Birthday]) throws -> String
}

public struct FormatterFactory: Sendable {
  public static func create(
    format: OutputFormat,
    isTTY: Bool,
    noColor: Bool,
    textOptions: TextFormatterOptions = TextFormatterOptions()
  ) -> any OutputFormatter {
    switch format {
    case .json:
      return JSONFormatter(pretty: isTTY)
    case .text:
      let colorizer: ANSIColorizer?
      if noColor {
        colorizer = nil
      } else {
        colorizer = ANSIColorizer.detect(isTTY: isTTY)
      }
      return TextFormatter(options: textOptions, colorizer: colorizer)
    }
  }

  /// Auto-detect format: text for TTY, JSON when piped.
  public static func autoDetect(
    isTTY: Bool,
    noColor: Bool,
    textOptions: TextFormatterOptions = TextFormatterOptions()
  ) -> any OutputFormatter {
    let format: OutputFormat = isTTY ? .text : .json
    return create(format: format, isTTY: isTTY, noColor: noColor, textOptions: textOptions)
  }
}
