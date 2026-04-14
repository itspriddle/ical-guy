import ArgumentParser

@main
struct ICalGuy: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ical-guy",
    abstract: "Query macOS calendar events and output as JSON or text.",
    version: "0.13.0",
    subcommands: [
      EventsCommand.self, CalendarsCommand.self, MeetingCommand.self, WeekCommand.self,
      RemindersCommand.self, BirthdaysCommand.self, ConflictsCommand.self, FreeCommand.self,
    ],
    defaultSubcommand: EventsCommand.self
  )
}
