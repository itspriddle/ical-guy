import ArgumentParser

@main
struct ICalGuy: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ical-guy",
    abstract: "Query macOS calendar events and output as JSON or text.",
    version: "0.4.0",
    subcommands: [
      EventsCommand.self, CalendarsCommand.self, MeetingCommand.self, WeekCommand.self,
    ],
    defaultSubcommand: EventsCommand.self
  )
}
