import Foundation

/// CLI flags passed from the argument parser.
public struct CLIOptions: Sendable {
  public let format: String?
  public let noColor: Bool
  public let excludeAllDay: Bool
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
  public let limit: Int?
  public let groupBy: String?
  public let showEmptyDates: Bool

  public init(
    format: String? = nil,
    noColor: Bool = false,
    excludeAllDay: Bool = false,
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil,
    limit: Int? = nil,
    groupBy: String? = nil,
    showEmptyDates: Bool = false
  ) {
    self.format = format
    self.noColor = noColor
    self.excludeAllDay = excludeAllDay
    self.includeCalendars = includeCalendars
    self.excludeCalendars = excludeCalendars
    self.limit = limit
    self.groupBy = groupBy
    self.showEmptyDates = showEmptyDates
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
  public let groupBy: GroupingMode?
  public let showEmptyDates: Bool

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

    let groupBy: GroupingMode?
    if let g = cli.groupBy {
      groupBy = GroupingMode(rawValue: g)
    } else if let g = config?.groupBy {
      groupBy = GroupingMode(rawValue: g)
    } else {
      groupBy = nil
    }

    let showEmptyDates = cli.showEmptyDates || (config?.showEmptyDates ?? false)

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
      textOptions: textOptions,
      groupBy: groupBy,
      showEmptyDates: showEmptyDates
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

  /// Build a GroupingContext, applying auto-detection logic.
  /// - `showEmptyDates` implies `.date` grouping
  /// - Multi-day ranges default to `.date` grouping
  /// - Single-day ranges default to `.none`
  public func makeGroupingContext(
    dateRange: DateRange?, isMultiDay: Bool
  ) -> GroupingContext {
    let mode: GroupingMode
    if let groupBy {
      mode = groupBy
    } else if showEmptyDates {
      mode = .date
    } else if isMultiDay {
      mode = .date
    } else {
      mode = .none
    }

    return GroupingContext(
      mode: mode,
      showEmptyDates: showEmptyDates,
      dateRange: dateRange
    )
  }

  public func makeFormatter(
    isTTY: Bool, grouping: GroupingContext = GroupingContext()
  ) -> any OutputFormatter {
    if let format {
      return FormatterFactory.create(
        format: format, isTTY: isTTY, noColor: noColor, textOptions: textOptions,
        grouping: grouping
      )
    }
    return FormatterFactory.autoDetect(
      isTTY: isTTY, noColor: noColor, textOptions: textOptions, grouping: grouping
    )
  }
}
