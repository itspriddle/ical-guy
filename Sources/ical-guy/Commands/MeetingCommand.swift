import AppKit
import ArgumentParser
import Foundation
import ICalGuyKit

struct MeetingCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "meeting",
    abstract: "View and manage meetings.",
    subcommands: [
      MeetingNowCommand.self,
      MeetingNextCommand.self,
      MeetingOpenCommand.self,
      MeetingListCommand.self,
    ]
  )
}

// MARK: - meeting now

struct MeetingNowCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "now",
    abstract: "Show current meeting details with time remaining."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Option(name: .long, help: "Only include these calendars (comma-separated titles).")
  var includeCalendars: String?

  @Option(name: .long, help: "Exclude these calendars (comma-separated titles).")
  var excludeCalendars: String?

  func run() async throws {
    let store = LiveEventStore()
    try await store.requestAccess()

    let service = MeetingService(store: store)
    guard
      let context = try service.currentMeeting(
        includeCalendars: parseCSV(includeCalendars),
        excludeCalendars: parseCSV(excludeCalendars)
      )
    else {
      throw CleanExit.message("No current meeting.")
    }

    let isTTY = isatty(fileno(stdout)) != 0
    let asJSON = resolveJSON(globalOptions.format, isTTY: isTTY)
    let colorizer = resolveColorizer(globalOptions.noColor, isTTY: isTTY)
    let formatter = MeetingFormatter(colorizer: colorizer)
    print(try formatter.formatMeeting(context, asJSON: asJSON))
  }
}

// MARK: - meeting next

struct MeetingNextCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "next",
    abstract: "Show next upcoming meeting with time until start."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Option(name: .long, help: "Only include these calendars (comma-separated titles).")
  var includeCalendars: String?

  @Option(name: .long, help: "Exclude these calendars (comma-separated titles).")
  var excludeCalendars: String?

  func run() async throws {
    let store = LiveEventStore()
    try await store.requestAccess()

    let service = MeetingService(store: store)
    guard
      let context = try service.nextMeeting(
        includeCalendars: parseCSV(includeCalendars),
        excludeCalendars: parseCSV(excludeCalendars)
      )
    else {
      throw CleanExit.message("No upcoming meetings today.")
    }

    let isTTY = isatty(fileno(stdout)) != 0
    let asJSON = resolveJSON(globalOptions.format, isTTY: isTTY)
    let colorizer = resolveColorizer(globalOptions.noColor, isTTY: isTTY)
    let formatter = MeetingFormatter(colorizer: colorizer)
    print(try formatter.formatMeeting(context, asJSON: asJSON))
  }
}

// MARK: - meeting open

struct MeetingOpenCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "open",
    abstract: "Open current meeting URL in browser."
  )

  @Flag(name: .long, help: "Open the next upcoming meeting instead of the current one.")
  var next: Bool = false

  @Option(name: .long, help: "Only include these calendars (comma-separated titles).")
  var includeCalendars: String?

  @Option(name: .long, help: "Exclude these calendars (comma-separated titles).")
  var excludeCalendars: String?

  func run() async throws {
    let store = LiveEventStore()
    try await store.requestAccess()

    let service = MeetingService(store: store)
    let include = parseCSV(includeCalendars)
    let exclude = parseCSV(excludeCalendars)

    let context: MeetingContext?
    if next {
      context = try service.nextMeeting(includeCalendars: include, excludeCalendars: exclude)
    } else {
      context = try service.currentMeeting(includeCalendars: include, excludeCalendars: exclude)
    }

    guard let context else {
      let which = next ? "upcoming" : "current"
      throw CleanExit.message("No \(which) meeting.")
    }

    guard let meetingUrl = context.event.meetingUrl else {
      throw CleanExit.message("Meeting \"\(context.event.title)\" has no meeting URL.")
    }

    guard let url = URL(string: meetingUrl) else {
      throw CleanExit.message("Invalid meeting URL: \(meetingUrl)")
    }

    NSWorkspace.shared.open(url)
  }
}

// MARK: - meeting list

struct MeetingListCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "List today's meetings."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Option(name: .long, help: "Only include these calendars (comma-separated titles).")
  var includeCalendars: String?

  @Option(name: .long, help: "Exclude these calendars (comma-separated titles).")
  var excludeCalendars: String?

  func run() async throws {
    let store = LiveEventStore()
    try await store.requestAccess()

    let service = MeetingService(store: store)
    let meetings = try service.todaysMeetings(
      includeCalendars: parseCSV(includeCalendars),
      excludeCalendars: parseCSV(excludeCalendars)
    )

    let isTTY = isatty(fileno(stdout)) != 0
    let asJSON = resolveJSON(globalOptions.format, isTTY: isTTY)
    let colorizer = resolveColorizer(globalOptions.noColor, isTTY: isTTY)
    let formatter = MeetingFormatter(colorizer: colorizer)
    print(try formatter.formatMeetingList(meetings, asJSON: asJSON))
  }
}

// MARK: - Helpers

private func parseCSV(_ value: String?) -> [String]? {
  value?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
}

private func resolveJSON(_ format: String?, isTTY: Bool) -> Bool {
  if let format { return format == "json" }
  return !isTTY
}

private func resolveColorizer(_ noColor: Bool, isTTY: Bool) -> ANSIColorizer? {
  if noColor { return nil }
  return ANSIColorizer.detect(isTTY: isTTY)
}
