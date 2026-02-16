import ArgumentParser
import Foundation
import ICalGuyKit

struct EventsCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "events",
    abstract: "Query calendar events."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Option(name: .long, help: "Start date (ISO 8601, 'today', 'tomorrow', 'yesterday', 'today+N').")
  var from: String?

  @Option(name: .long, help: "End date (same formats as --from).")
  var to: String?

  @Option(name: .long, help: "Only include these calendars (comma-separated titles).")
  var includeCalendars: String?

  @Option(name: .long, help: "Exclude these calendars (comma-separated titles).")
  var excludeCalendars: String?

  @Flag(name: .long, help: "Exclude all-day events.")
  var excludeAllDay = false

  @Option(name: .long, help: "Maximum number of events to output.")
  var limit: Int?

  func run() async throws {
    let config = try? ConfigLoader.load()

    let parsedInclude = includeCalendars?.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
    let parsedExclude = excludeCalendars?.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }

    let cli = CLIOptions(
      format: globalOptions.format,
      noColor: globalOptions.noColor,
      excludeAllDay: excludeAllDay,
      includeCalendars: parsedInclude,
      excludeCalendars: parsedExclude,
      limit: limit,
      groupBy: globalOptions.groupBy,
      showEmptyDates: globalOptions.showEmptyDates
    )
    let runtimeOpts = RuntimeOptions.resolve(config: config, cli: cli)

    let store = LiveEventStore()
    try await store.requestAccess()

    let dateParser = DateParser()
    let fromDate: Date
    let toDate: Date

    if let fromInput = from {
      fromDate = try dateParser.parse(fromInput)
    } else {
      fromDate = dateParser.startOfDay(Date())
    }

    if let toInput = to {
      toDate = try dateParser.parse(toInput)
    } else {
      toDate = dateParser.endOfDay(fromDate)
    }

    let serviceOptions = runtimeOpts.toEventServiceOptions(from: fromDate, to: toDate)
    let service = EventService(store: store)
    let events = try service.fetchEvents(options: serviceOptions)

    let isMultiDay = !Calendar.current.isDate(fromDate, inSameDayAs: toDate)
    let dateRange = DateRange(from: fromDate, to: toDate)
    let grouping = runtimeOpts.makeGroupingContext(dateRange: dateRange, isMultiDay: isMultiDay)

    let isTTY = isatty(fileno(stdout)) != 0
    let formatter = runtimeOpts.makeFormatter(isTTY: isTTY, grouping: grouping)
    let output = try formatter.formatEvents(events)
    print(output)
  }
}
