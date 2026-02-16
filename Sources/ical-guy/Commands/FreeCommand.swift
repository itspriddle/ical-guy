import ArgumentParser
import Foundation
import ICalGuyKit

struct FreeCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "free",
    abstract: "Find free time slots for deep work planning."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Option(
    name: .long,
    help: "Start date (ISO 8601, 'today', 'tomorrow', 'now', 'today+N')."
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

  @Flag(name: .long, help: "Include all-day events as busy time.")
  var includeAllDay = false

  @Option(name: .long, help: "Minimum free slot duration in minutes (default: 30).")
  var minDuration: Int?

  @Option(name: .long, help: "Working hours start (HH:MM, default: 09:00).")
  var workStart: String?

  @Option(name: .long, help: "Working hours end (HH:MM, default: 17:00).")
  var workEnd: String?

  func run() async throws {
    let config = try? ConfigLoader.load()

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

    let resolvedMinDuration = minDuration ?? config?.freeMinDuration ?? 30
    let resolvedWorkStart = workStart ?? config?.freeWorkStart ?? "09:00"
    let resolvedWorkEnd = workEnd ?? config?.freeWorkEnd ?? "17:00"

    let workingHours =
      WorkingHours.from(
        start: resolvedWorkStart, end: resolvedWorkEnd
      ) ?? .default

    let options = FreeTimeServiceOptions(
      from: fromDate,
      to: toDate,
      includeCalendars: parseCSV(includeCalendars),
      excludeCalendars: parseCSV(excludeCalendars),
      includeAllDay: includeAllDay,
      minDuration: resolvedMinDuration,
      workingHours: workingHours
    )

    let service = FreeTimeService(store: store)
    let result = try service.findFreeTime(options: options)

    let isTTY = isatty(fileno(stdout)) != 0
    let asJSON = resolveJSON(globalOptions.format, isTTY: isTTY)
    let colorizer = resolveColorizer(globalOptions.noColor, isTTY: isTTY)
    let formatter = FreeTimeFormatter(colorizer: colorizer)
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
