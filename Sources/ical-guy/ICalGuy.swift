import ArgumentParser

@main
struct ICalGuy: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ical-guy",
    abstract: "Query macOS calendar events and output as JSON or text.",
    version: "1.0.0",
    subcommands: [EventsCommand.self, CalendarsCommand.self, MeetingCommand.self],
    defaultSubcommand: EventsCommand.self
  )
}
