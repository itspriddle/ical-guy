import Foundation
import Mustache

private struct CompiledTemplates {
  let event: MustacheTemplate?
  let dateHeader: MustacheTemplate?
  let calendarHeader: MustacheTemplate?
}

/// CLI flags passed from the argument parser.
public struct CLIOptions: Sendable {
  public let format: String?
  public let noColor: Bool
  public let excludeAllDay: Bool
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
  public let includeCalendarTypes: [String]?
  public let excludeCalendarTypes: [String]?
  public let limit: Int?
  public let groupBy: String?
  public let showEmptyDates: Bool
  public let timeFormat: String?
  public let dateFormat: String?
  public let showUid: Bool
  public let templateFile: String?
  public let bullet: String?
  public let separator: String?
  public let indent: String?
  public let truncateNotes: Int?
  public let truncateLocation: Int?
  public let maxAttendees: Int?
  public let hide: [String]?

  public init(
    format: String? = nil,
    noColor: Bool = false,
    excludeAllDay: Bool = false,
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil,
    includeCalendarTypes: [String]? = nil,
    excludeCalendarTypes: [String]? = nil,
    limit: Int? = nil,
    groupBy: String? = nil,
    showEmptyDates: Bool = false,
    timeFormat: String? = nil,
    dateFormat: String? = nil,
    showUid: Bool = false,
    templateFile: String? = nil,
    bullet: String? = nil,
    separator: String? = nil,
    indent: String? = nil,
    truncateNotes: Int? = nil,
    truncateLocation: Int? = nil,
    maxAttendees: Int? = nil,
    hide: [String]? = nil
  ) {
    self.format = format
    self.noColor = noColor
    self.excludeAllDay = excludeAllDay
    self.includeCalendars = includeCalendars
    self.excludeCalendars = excludeCalendars
    self.includeCalendarTypes = includeCalendarTypes
    self.excludeCalendarTypes = excludeCalendarTypes
    self.limit = limit
    self.groupBy = groupBy
    self.showEmptyDates = showEmptyDates
    self.timeFormat = timeFormat
    self.dateFormat = dateFormat
    self.showUid = showUid
    self.templateFile = templateFile
    self.bullet = bullet
    self.separator = separator
    self.indent = indent
    self.truncateNotes = truncateNotes
    self.truncateLocation = truncateLocation
    self.maxAttendees = maxAttendees
    self.hide = hide
  }
}

/// Resolved runtime options after merging config file defaults with CLI flags.
public struct RuntimeOptions: Sendable {
  public let format: OutputFormat?
  public let noColor: Bool
  public let excludeAllDay: Bool
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
  public let includeCalendarTypes: [String]?
  public let excludeCalendarTypes: [String]?
  public let limit: Int?
  public let textOptions: TextFormatterOptions
  public let groupBy: GroupingMode?
  public let showEmptyDates: Bool
  public let dateFormats: TemplateDateFormats
  public let truncation: TruncationLimits
  public let decorations: TemplateDecorations
  public let eventTemplate: MustacheTemplate?
  public let dateHeaderTemplate: MustacheTemplate?
  public let calendarHeaderTemplate: MustacheTemplate?

  /// Merge config defaults with CLI overrides.
  /// CLI values take precedence when non-nil.
  /// Throws if template strings contain invalid Mustache syntax.
  public static func resolve(
    config: UserConfig?, cli: CLIOptions
  ) throws -> RuntimeOptions {
    let format = (cli.format ?? config?.format).flatMap(OutputFormat.init)
    let groupBy = (cli.groupBy ?? config?.groupBy).flatMap(GroupingMode.init)
    let templates = try Self.compileTemplates(config, cliTemplateFile: cli.templateFile)

    let hideSet = Set(cli.hide?.map { $0.lowercased() } ?? [])

    return RuntimeOptions(
      format: format,
      noColor: cli.noColor,
      excludeAllDay: cli.excludeAllDay || (config?.excludeAllDay ?? false),
      includeCalendars: cli.includeCalendars ?? config?.includeCalendars,
      excludeCalendars: cli.excludeCalendars ?? config?.excludeCalendars,
      includeCalendarTypes: cli.includeCalendarTypes ?? config?.includeCalendarTypes,
      excludeCalendarTypes: cli.excludeCalendarTypes ?? config?.excludeCalendarTypes,
      limit: cli.limit,
      textOptions: TextFormatterOptions(
        showCalendar: (config?.showCalendar ?? true) && !hideSet.contains("calendar"),
        showLocation: (config?.showLocation ?? true) && !hideSet.contains("location"),
        showAttendees: (config?.showAttendees ?? true) && !hideSet.contains("attendees"),
        showMeetingUrl: (config?.showMeetingUrl ?? true) && !hideSet.contains("meeting-url"),
        showNotes: (config?.showNotes ?? false) && !hideSet.contains("notes"),
        showUid: (cli.showUid || (config?.showUid ?? false)) && !hideSet.contains("uid")
      ),
      groupBy: groupBy,
      showEmptyDates: cli.showEmptyDates || (config?.showEmptyDates ?? false),
      dateFormats: TemplateDateFormats(
        timeFormat: cli.timeFormat ?? config?.timeFormat ?? "h:mm a",
        dateFormat: cli.dateFormat ?? config?.dateFormat ?? "EEEE, MMM d, yyyy"
      ),
      truncation: TruncationLimits(
        notes: cli.truncateNotes ?? config?.truncateNotes,
        location: cli.truncateLocation ?? config?.truncateLocation,
        attendees: cli.maxAttendees ?? config?.maxAttendees
      ),
      decorations: TemplateDecorations(
        bullet: cli.bullet ?? config?.bullet ?? "",
        separator: cli.separator ?? config?.separator ?? "",
        indent: cli.indent ?? config?.indent ?? "    "
      ),
      eventTemplate: templates.event,
      dateHeaderTemplate: templates.dateHeader,
      calendarHeaderTemplate: templates.calendarHeader
    )
  }

  public func toEventServiceOptions(
    from: Date, to: Date, overlapsWith: Date? = nil
  ) -> EventServiceOptions {
    EventServiceOptions(
      from: from,
      to: to,
      includeCalendars: includeCalendars,
      excludeCalendars: excludeCalendars,
      includeCalendarTypes: includeCalendarTypes,
      excludeCalendarTypes: excludeCalendarTypes,
      excludeAllDay: excludeAllDay,
      limit: limit,
      overlapsWith: overlapsWith
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
  ) throws -> any OutputFormatter {
    if let format {
      return try FormatterFactory.create(
        format: format, isTTY: isTTY, noColor: noColor,
        textOptions: textOptions, grouping: grouping,
        dateFormats: dateFormats, truncation: truncation,
        decorations: decorations,
        eventTemplate: eventTemplate,
        dateHeaderTemplate: dateHeaderTemplate,
        calendarHeaderTemplate: calendarHeaderTemplate
      )
    }
    return try FormatterFactory.autoDetect(
      isTTY: isTTY, noColor: noColor, textOptions: textOptions,
      grouping: grouping, dateFormats: dateFormats,
      truncation: truncation, decorations: decorations,
      eventTemplate: eventTemplate,
      dateHeaderTemplate: dateHeaderTemplate,
      calendarHeaderTemplate: calendarHeaderTemplate
    )
  }

  private static func compileTemplates(
    _ config: UserConfig?, cliTemplateFile: String? = nil
  ) throws -> CompiledTemplates {
    CompiledTemplates(
      event: try compileTemplateWithFile(
        inline: config?.eventTemplate,
        file: cliTemplateFile ?? config?.eventTemplateFile,
        name: "event"
      ),
      dateHeader: try compileTemplateWithFile(
        inline: config?.dateHeaderTemplate,
        file: config?.dateHeaderTemplateFile,
        name: "date-header"
      ),
      calendarHeader: try compileTemplateWithFile(
        inline: config?.calendarHeaderTemplate,
        file: config?.calendarHeaderTemplateFile,
        name: "calendar-header"
      )
    )
  }

  /// Load template from file (takes precedence) or inline string.
  private static func compileTemplateWithFile(
    inline: String?, file: String?, name: String
  ) throws -> MustacheTemplate? {
    if let file {
      let source = try loadTemplateFile(file, name: name)
      return try compileTemplate(source, name: name)
    }
    guard let inline else { return nil }
    return try compileTemplate(inline, name: name)
  }

  static var templateBaseDirectory: String {
    let xdg =
      ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
      ?? "\(NSHomeDirectory())/.config"
    return "\(xdg)/ical-guy/templates"
  }

  private static func loadTemplateFile(
    _ path: String, name: String
  ) throws -> String {
    let resolvedPath: String
    if path.hasPrefix("/") {
      resolvedPath = path
    } else {
      resolvedPath = "\(templateBaseDirectory)/\(path)"
    }

    guard FileManager.default.fileExists(atPath: resolvedPath) else {
      throw ConfigError.templateFileNotFound(
        name: name, path: resolvedPath
      )
    }

    do {
      return try String(contentsOfFile: resolvedPath, encoding: .utf8)
    } catch {
      throw ConfigError.parseError(
        "Could not read template file '\(name)' at "
          + "\(resolvedPath): \(error.localizedDescription)"
      )
    }
  }

  private static func compileTemplate(
    _ source: String, name: String
  ) throws -> MustacheTemplate? {
    do {
      return try MustacheTemplate(string: source)
    } catch {
      throw ConfigError.parseError(
        "Invalid Mustache syntax in template '\(name)': \(error)"
      )
    }
  }
}
