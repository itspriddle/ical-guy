import ArgumentParser
import Foundation
import ICalGuyKit

struct EventsCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "events",
    abstract: "Query calendar events. Supports Mustache templates for text output."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Option(name: .long, help: "Start date (ISO 8601, 'today', 'tomorrow', 'yesterday', 'today+N', or natural language).")
  var from: String?

  @Option(name: .long, help: "End date (same formats as --from).")
  var to: String?

  @Option(name: .long, help: "Only include these calendars (comma-separated titles).")
  var includeCalendars: String?

  @Option(name: .long, help: "Exclude these calendars (comma-separated titles).")
  var excludeCalendars: String?

  @Option(
    name: .long,
    help:
      "Only include these calendar types (local, calDAV, exchange, subscription, birthday, icloud)."
  )
  var includeCalTypes: String?

  @Option(
    name: .long,
    help: "Exclude these calendar types (local, calDAV, exchange, subscription, birthday, icloud)."
  )
  var excludeCalTypes: String?

  @Flag(name: .long, help: "Exclude all-day events.")
  var excludeAllDay = false

  @Option(name: .long, help: "Maximum number of events to output.")
  var limit: Int?

  @Option(
    name: .long,
    help: "Path to a .mustache template file for event rendering (overrides config)."
  )
  var template: String?

  func run() async throws {
    let config = try? ConfigLoader.load()

    let parsedInclude = includeCalendars?.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
    let parsedExclude = excludeCalendars?.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
    let parsedIncludeTypes = includeCalTypes?.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
    let parsedExcludeTypes = excludeCalTypes?.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }

    let cli = CLIOptions(
      format: globalOptions.format,
      noColor: globalOptions.noColor,
      excludeAllDay: excludeAllDay,
      includeCalendars: parsedInclude,
      excludeCalendars: parsedExclude,
      includeCalendarTypes: parsedIncludeTypes,
      excludeCalendarTypes: parsedExcludeTypes,
      limit: limit,
      groupBy: globalOptions.groupBy,
      showEmptyDates: globalOptions.showEmptyDates,
      timeFormat: globalOptions.timeFormat,
      dateFormat: globalOptions.dateFormat,
      showUid: globalOptions.showUid,
      templateFile: template,
      bullet: globalOptions.bullet,
      separator: globalOptions.separator,
      indent: globalOptions.indent,
      truncateNotes: globalOptions.truncateNotes,
      truncateLocation: globalOptions.truncateLocation,
      maxAttendees: globalOptions.maxAttendees
    )
    let runtimeOpts = try RuntimeOptions.resolve(config: config, cli: cli)

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
    let formatter = try runtimeOpts.makeFormatter(isTTY: isTTY, grouping: grouping)
    let output = try formatter.formatEvents(events)
    print(output)
  }
}
