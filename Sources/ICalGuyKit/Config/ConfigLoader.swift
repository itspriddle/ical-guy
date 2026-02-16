import Foundation
import TOMLKit

public struct UserConfig: Sendable, Equatable {
  public let format: String?
  public let excludeAllDay: Bool?
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
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

  public init(
    format: String? = nil,
    excludeAllDay: Bool? = nil,
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil,
    showCalendar: Bool? = nil,
    showLocation: Bool? = nil,
    showAttendees: Bool? = nil,
    showMeetingUrl: Bool? = nil,
    showNotes: Bool? = nil,
    groupBy: String? = nil,
    showEmptyDates: Bool? = nil,
    freeMinDuration: Int? = nil,
    freeWorkStart: String? = nil,
    freeWorkEnd: String? = nil
  ) {
    self.format = format
    self.excludeAllDay = excludeAllDay
    self.includeCalendars = includeCalendars
    self.excludeCalendars = excludeCalendars
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
  }
}

public enum ConfigError: Error, LocalizedError {
  case parseError(String)

  public var errorDescription: String? {
    switch self {
    case .parseError(let message):
      return "Config parse error: \(message)"
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
  /// Returns nil if the file doesn't exist (config is optional).
  /// Throws if the file exists but can't be parsed.
  public static func load(from path: String? = nil) throws -> UserConfig? {
    let configPath = path ?? defaultPath

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
    let defaults = table["defaults"] as? TOMLTable

    let format = defaults?["format"] as? String
    let excludeAllDay = defaults?["exclude-all-day"] as? Bool
    let includeCalendars = tomlStringArray(defaults?["include-calendars"])
    let excludeCalendars = tomlStringArray(defaults?["exclude-calendars"])
    let groupBy = defaults?["group-by"] as? String
    let showEmptyDates = defaults?["show-empty-dates"] as? Bool

    let text = table["text"] as? TOMLTable
    let free = table["free"] as? TOMLTable

    return UserConfig(
      format: format,
      excludeAllDay: excludeAllDay,
      includeCalendars: includeCalendars,
      excludeCalendars: excludeCalendars,
      showCalendar: text?["show-calendar"] as? Bool,
      showLocation: text?["show-location"] as? Bool,
      showAttendees: text?["show-attendees"] as? Bool,
      showMeetingUrl: text?["show-meeting-url"] as? Bool,
      showNotes: text?["show-notes"] as? Bool,
      groupBy: groupBy,
      showEmptyDates: showEmptyDates,
      freeMinDuration: free?["min-duration"] as? Int,
      freeWorkStart: free?["work-start"] as? String,
      freeWorkEnd: free?["work-end"] as? String
    )
  }

  private static func tomlStringArray(_ value: Any?) -> [String]? {
    guard let array = value as? TOMLArray else { return nil }
    var result: [String] = []
    for i in 0..<array.count {
      if let str = array[i] as? String {
        result.append(str)
      }
    }
    return result.isEmpty ? nil : result
  }
}
