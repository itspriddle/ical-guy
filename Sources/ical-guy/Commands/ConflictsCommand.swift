import ArgumentParser
import Foundation
import ICalGuyKit

struct ConflictsCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "conflicts",
    abstract: "Detect double-booked events in a date range."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Option(
    name: .long,
    help: "Start date (ISO 8601, 'today', 'tomorrow', 'yesterday', 'today+N')."
  )
  var from: String?

  @Option(name: .long, help: "End date (same formats as --from).")
  var to: String?

  @Option(
    name: .long,
    help: "Only include these calendars (comma-separated titles)."
  )
  var includeCalendars: String?

  @Option(
    name: .long,
    help: "Exclude these calendars (comma-separated titles)."
  )
  var excludeCalendars: String?

  @Flag(name: .long, help: "Include all-day events in conflict detection.")
  var includeAllDay = false

  func run() async throws {
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

    let options = ConflictServiceOptions(
      from: fromDate,
      to: toDate,
      includeCalendars: parseCSV(includeCalendars),
      excludeCalendars: parseCSV(excludeCalendars),
      includeAllDay: includeAllDay
    )

    let service = ConflictService(store: store)
    let result = try service.findConflicts(options: options)

    let isTTY = isatty(fileno(stdout)) != 0
    let asJSON = resolveJSON(globalOptions.format, isTTY: isTTY)
    let colorizer = resolveColorizer(globalOptions.noColor, isTTY: isTTY)
    let formatter = ConflictFormatter(colorizer: colorizer)
    print(try formatter.format(result, asJSON: asJSON))
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
