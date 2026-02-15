import Foundation

/// CLI flags passed from the argument parser.
public struct CLIOptions: Sendable {
  public let format: String?
  public let noColor: Bool
  public let excludeAllDay: Bool
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
  public let limit: Int?

  public init(
    format: String? = nil,
    noColor: Bool = false,
    excludeAllDay: Bool = false,
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil,
    limit: Int? = nil
  ) {
    self.format = format
    self.noColor = noColor
    self.excludeAllDay = excludeAllDay
    self.includeCalendars = includeCalendars
    self.excludeCalendars = excludeCalendars
    self.limit = limit
  }
}

/// Resolved runtime options after merging config file defaults with CLI flags.
public struct RuntimeOptions: Sendable {
  public let format: OutputFormat?
  public let noColor: Bool
  public let excludeAllDay: Bool
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
  public let limit: Int?
  public let textOptions: TextFormatterOptions

  /// Merge config defaults with CLI overrides.
  /// CLI values take precedence when non-nil.
  public static func resolve(config: UserConfig?, cli: CLIOptions) -> RuntimeOptions {
    let format: OutputFormat?
    if let f = cli.format {
      format = OutputFormat(rawValue: f)
    } else if let f = config?.format {
      format = OutputFormat(rawValue: f)
    } else {
      format = nil  // auto-detect
    }

    let excludeAllDay = cli.excludeAllDay || (config?.excludeAllDay ?? false)
    let includeCalendars = cli.includeCalendars ?? config?.includeCalendars
    let excludeCalendars = cli.excludeCalendars ?? config?.excludeCalendars

    let textOptions = TextFormatterOptions(
      showCalendar: config?.showCalendar ?? true,
      showLocation: config?.showLocation ?? true,
      showAttendees: config?.showAttendees ?? true,
      showMeetingUrl: config?.showMeetingUrl ?? true,
      showNotes: config?.showNotes ?? false
    )

    return RuntimeOptions(
      format: format,
      noColor: cli.noColor,
      excludeAllDay: excludeAllDay,
      includeCalendars: includeCalendars,
      excludeCalendars: excludeCalendars,
      limit: cli.limit,
      textOptions: textOptions
    )
  }

  public func toEventServiceOptions(from: Date, to: Date) -> EventServiceOptions {
    EventServiceOptions(
      from: from,
      to: to,
      includeCalendars: includeCalendars,
      excludeCalendars: excludeCalendars,
      excludeAllDay: excludeAllDay,
      limit: limit
    )
  }

  public func makeFormatter(isTTY: Bool) -> any OutputFormatter {
    if let format {
      return FormatterFactory.create(
        format: format, isTTY: isTTY, noColor: noColor, textOptions: textOptions
      )
    }
    return FormatterFactory.autoDetect(isTTY: isTTY, noColor: noColor, textOptions: textOptions)
  }
}
