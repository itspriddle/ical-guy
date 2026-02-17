import Foundation
import Mustache

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
    textOptions: TextFormatterOptions = TextFormatterOptions(),
    grouping: GroupingContext = GroupingContext(),
    dateFormats: TemplateDateFormats = TemplateDateFormats(),
    truncation: TruncationLimits = TruncationLimits(),
    decorations: TemplateDecorations = TemplateDecorations(),
    eventTemplate: MustacheTemplate? = nil,
    dateHeaderTemplate: MustacheTemplate? = nil,
    calendarHeaderTemplate: MustacheTemplate? = nil
  ) throws -> any OutputFormatter {
    switch format {
    case .json:
      return JSONFormatter(pretty: isTTY, grouping: grouping)
    case .text:
      let colorizer: ANSIColorizer?
      if noColor {
        colorizer = nil
      } else {
        colorizer = ANSIColorizer.detect(isTTY: isTTY)
      }
      return try TemplateFormatter(
        options: textOptions, colorizer: colorizer,
        grouping: grouping,
        eventTemplate: eventTemplate,
        dateHeaderTemplate: dateHeaderTemplate,
        calendarHeaderTemplate: calendarHeaderTemplate,
        dateFormats: dateFormats,
        truncation: truncation,
        decorations: decorations
      )
    }
  }

  /// Auto-detect format: text for TTY, JSON when piped.
  public static func autoDetect(
    isTTY: Bool,
    noColor: Bool,
    textOptions: TextFormatterOptions = TextFormatterOptions(),
    grouping: GroupingContext = GroupingContext(),
    dateFormats: TemplateDateFormats = TemplateDateFormats(),
    truncation: TruncationLimits = TruncationLimits(),
    decorations: TemplateDecorations = TemplateDecorations(),
    eventTemplate: MustacheTemplate? = nil,
    dateHeaderTemplate: MustacheTemplate? = nil,
    calendarHeaderTemplate: MustacheTemplate? = nil
  ) throws -> any OutputFormatter {
    let format: OutputFormat = isTTY ? .text : .json
    return try create(
      format: format, isTTY: isTTY, noColor: noColor,
      textOptions: textOptions, grouping: grouping,
      dateFormats: dateFormats, truncation: truncation,
      decorations: decorations,
      eventTemplate: eventTemplate,
      dateHeaderTemplate: dateHeaderTemplate,
      calendarHeaderTemplate: calendarHeaderTemplate
    )
  }
}
