import Foundation
import TOMLKit

public struct BrowserConfig: Sendable, Equatable {
  public let defaultBrowser: String?
  public let meet: String?
  public let zoom: String?
  public let teams: String?
  public let webex: String?

  public init(
    defaultBrowser: String? = nil,
    meet: String? = nil,
    zoom: String? = nil,
    teams: String? = nil,
    webex: String? = nil
  ) {
    self.defaultBrowser = defaultBrowser
    self.meet = meet
    self.zoom = zoom
    self.teams = teams
    self.webex = webex
  }

  /// Returns the browser name for a given vendor, falling back to default.
  public func browser(for vendor: MeetingVendor?) -> String? {
    if let vendor {
      let vendorBrowser: String? =
        switch vendor {
        case .meet: meet
        case .zoom: zoom
        case .teams: teams
        case .webex: webex
        }
      if let vendorBrowser {
        return vendorBrowser
      }
    }
    return defaultBrowser
  }
}

public struct UserConfig: Sendable, Equatable {
  public let format: String?
  public let excludeAllDay: Bool?
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
  public let includeCalendarTypes: [String]?
  public let excludeCalendarTypes: [String]?
  public let showCalendar: Bool?
  public let showLocation: Bool?
  public let showAttendees: Bool?
  public let showMeetingUrl: Bool?
  public let showNotes: Bool?
  public let groupBy: String?
  public let showEmptyDates: Bool?
  public let freeMinDuration: Int?
  public let freeWorkStart: String?
  public let freeWorkEnd: String?
  public let timeFormat: String?
  public let dateFormat: String?
  public let eventTemplate: String?
  public let dateHeaderTemplate: String?
  public let calendarHeaderTemplate: String?
  public let eventTemplateFile: String?
  public let dateHeaderTemplateFile: String?
  public let calendarHeaderTemplateFile: String?
  public let showUid: Bool?
  public let truncateNotes: Int?
  public let truncateLocation: Int?
  public let maxAttendees: Int?
  public let bullet: String?
  public let separator: String?
  public let indent: String?
  public let browsers: BrowserConfig?

  public init(
    format: String? = nil,
    excludeAllDay: Bool? = nil,
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil,
    includeCalendarTypes: [String]? = nil,
    excludeCalendarTypes: [String]? = nil,
    showCalendar: Bool? = nil,
    showLocation: Bool? = nil,
    showAttendees: Bool? = nil,
    showMeetingUrl: Bool? = nil,
    showNotes: Bool? = nil,
    groupBy: String? = nil,
    showEmptyDates: Bool? = nil,
    freeMinDuration: Int? = nil,
    freeWorkStart: String? = nil,
    freeWorkEnd: String? = nil,
    timeFormat: String? = nil,
    dateFormat: String? = nil,
    eventTemplate: String? = nil,
    dateHeaderTemplate: String? = nil,
    calendarHeaderTemplate: String? = nil,
    eventTemplateFile: String? = nil,
    dateHeaderTemplateFile: String? = nil,
    calendarHeaderTemplateFile: String? = nil,
    showUid: Bool? = nil,
    truncateNotes: Int? = nil,
    truncateLocation: Int? = nil,
    maxAttendees: Int? = nil,
    bullet: String? = nil,
    separator: String? = nil,
    indent: String? = nil,
    browsers: BrowserConfig? = nil
  ) {
    self.format = format
    self.excludeAllDay = excludeAllDay
    self.includeCalendars = includeCalendars
    self.excludeCalendars = excludeCalendars
    self.includeCalendarTypes = includeCalendarTypes
    self.excludeCalendarTypes = excludeCalendarTypes
    self.showCalendar = showCalendar
    self.showLocation = showLocation
    self.showAttendees = showAttendees
    self.showMeetingUrl = showMeetingUrl
    self.showNotes = showNotes
    self.groupBy = groupBy
    self.showEmptyDates = showEmptyDates
    self.freeMinDuration = freeMinDuration
    self.freeWorkStart = freeWorkStart
    self.freeWorkEnd = freeWorkEnd
    self.timeFormat = timeFormat
    self.dateFormat = dateFormat
    self.eventTemplate = eventTemplate
    self.dateHeaderTemplate = dateHeaderTemplate
    self.calendarHeaderTemplate = calendarHeaderTemplate
    self.eventTemplateFile = eventTemplateFile
    self.dateHeaderTemplateFile = dateHeaderTemplateFile
    self.calendarHeaderTemplateFile = calendarHeaderTemplateFile
    self.showUid = showUid
    self.truncateNotes = truncateNotes
    self.truncateLocation = truncateLocation
    self.maxAttendees = maxAttendees
    self.bullet = bullet
    self.separator = separator
    self.indent = indent
    self.browsers = browsers
  }
}

public enum ConfigError: Error, LocalizedError {
  case parseError(String)
  case templateFileNotFound(name: String, path: String)

  public var errorDescription: String? {
    switch self {
    case .parseError(let message):
      return "Config parse error: \(message)"
    case .templateFileNotFound(let name, let path):
      return "Template file not found for '\(name)': \(path)"
    }
  }
}

public struct ConfigLoader: Sendable {
  public static var defaultPath: String {
    let xdg =
      ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
      ?? "\(NSHomeDirectory())/.config"
    return "\(xdg)/ical-guy/config.toml"
  }

  /// Load config from the given path, or the default path if nil.
  /// Precedence: explicit path > ICAL_GUY_CONFIG env var > default path.
  /// Returns nil if the file doesn't exist (config is optional).
  /// Throws if the file exists but can't be parsed.
  public static func load(from path: String? = nil) throws -> UserConfig? {
    let configPath =
      path
      ?? ProcessInfo.processInfo.environment["ICAL_GUY_CONFIG"]
      ?? defaultPath

    guard FileManager.default.fileExists(atPath: configPath) else {
      return nil
    }

    let content: String
    do {
      content = try String(contentsOfFile: configPath, encoding: .utf8)
    } catch {
      throw ConfigError.parseError("Could not read \(configPath): \(error.localizedDescription)")
    }

    let table: TOMLTable
    do {
      table = try TOMLTable(string: content)
    } catch {
      throw ConfigError.parseError("\(error)")
    }

    return parseConfig(table)
  }

  private static func parseConfig(_ table: TOMLTable) -> UserConfig {
    let defaults = table["defaults"]?.table

    let format = defaults?["format"]?.string
    let excludeAllDay = defaults?["exclude-all-day"]?.bool
    let includeCalendars = tomlStringArray(defaults?["include-calendars"])
    let excludeCalendars = tomlStringArray(defaults?["exclude-calendars"])
    let includeCalendarTypes = tomlStringArray(defaults?["include-cal-types"])
    let excludeCalendarTypes = tomlStringArray(defaults?["exclude-cal-types"])
    let groupBy = defaults?["group-by"]?.string
    let showEmptyDates = defaults?["show-empty-dates"]?.bool

    let text = table["text"]?.table
    let free = table["free"]?.table
    let templates = table["templates"]?.table
    let browsersTable = table["browsers"]?.table

    let browserConfig: BrowserConfig? =
      if let browsersTable {
        BrowserConfig(
          defaultBrowser: browsersTable["default"]?.string,
          meet: browsersTable["meet"]?.string,
          zoom: browsersTable["zoom"]?.string,
          teams: browsersTable["teams"]?.string,
          webex: browsersTable["webex"]?.string
        )
      } else {
        nil
      }

    return UserConfig(
      format: format,
      excludeAllDay: excludeAllDay,
      includeCalendars: includeCalendars,
      excludeCalendars: excludeCalendars,
      includeCalendarTypes: includeCalendarTypes,
      excludeCalendarTypes: excludeCalendarTypes,
      showCalendar: text?["show-calendar"]?.bool,
      showLocation: text?["show-location"]?.bool,
      showAttendees: text?["show-attendees"]?.bool,
      showMeetingUrl: text?["show-meeting-url"]?.bool,
      showNotes: text?["show-notes"]?.bool,
      groupBy: groupBy,
      showEmptyDates: showEmptyDates,
      freeMinDuration: free?["min-duration"]?.int,
      freeWorkStart: free?["work-start"]?.string,
      freeWorkEnd: free?["work-end"]?.string,
      timeFormat: templates?["time-format"]?.string,
      dateFormat: templates?["date-format"]?.string,
      eventTemplate: templates?["event"]?.string,
      dateHeaderTemplate: templates?["date-header"]?.string,
      calendarHeaderTemplate: templates?["calendar-header"]?.string,
      eventTemplateFile: templates?["event-file"]?.string,
      dateHeaderTemplateFile: templates?["date-header-file"]?.string,
      calendarHeaderTemplateFile: templates?["calendar-header-file"]?.string,
      showUid: text?["show-uid"]?.bool,
      truncateNotes: templates?["truncate-notes"]?.int,
      truncateLocation: templates?["truncate-location"]?.int,
      maxAttendees: templates?["max-attendees"]?.int,
      bullet: templates?["bullet"]?.string,
      separator: templates?["separator"]?.string,
      indent: templates?["indent"]?.string,
      browsers: browserConfig
    )
  }

  private static func tomlStringArray(_ value: TOMLValueConvertible?) -> [String]? {
    guard let array = value?.array else { return nil }
    var result: [String] = []
    for i in 0..<array.count {
      if let str = array[i].string {
        result.append(str)
      }
    }
    return result.isEmpty ? nil : result
  }
}
