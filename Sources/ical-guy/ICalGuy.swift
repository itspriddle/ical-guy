import ArgumentParser

@main
struct ICalGuy: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ical-guy",
        abstract: "Query macOS calendar events and output as JSON.",
        version: "0.1.0",
        subcommands: [EventsCommand.self, CalendarsCommand.self],
        defaultSubcommand: EventsCommand.self
    )
}
