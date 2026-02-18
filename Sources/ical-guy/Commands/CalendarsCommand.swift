import ArgumentParser
import Foundation
import ICalGuyKit

struct CalendarsCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "calendars",
    abstract: "List available calendars."
  )

  @OptionGroup var globalOptions: GlobalOptions

  func run() async throws {
    let config = try? ConfigLoader.load(from: globalOptions.config)

    let parsedHide = globalOptions.hide?.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }

    let cli = CLIOptions(
      format: globalOptions.format,
      noColor: globalOptions.noColor,
      hide: parsedHide
    )
    let runtimeOpts = try RuntimeOptions.resolve(config: config, cli: cli)

    let store = LiveEventStore()
    try await store.requestAccess()

    let service = EventService(store: store)
    let calendars = try service.fetchCalendars()

    let isTTY = isatty(fileno(stdout)) != 0
    let formatter = try runtimeOpts.makeFormatter(isTTY: isTTY)
    let output = try formatter.formatCalendars(calendars)
    print(output)
  }
}
