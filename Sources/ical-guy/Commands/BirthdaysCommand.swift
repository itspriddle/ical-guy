import ArgumentParser
import Foundation
import ICalGuyKit

struct BirthdaysCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "birthdays",
    abstract: "List upcoming birthdays from the Contacts birthday calendar."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Option(name: .long, help: "Start date (ISO 8601, 'today', 'tomorrow', 'yesterday', 'today+N', or natural language).")
  var from: String?

  @Option(name: .long, help: "End date (same formats as --from).")
  var to: String?

  @Option(name: .long, help: "Maximum number of birthdays to output.")
  var limit: Int?

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
      // Default: 30 days ahead
      toDate = dateParser.endOfDay(
        Calendar.current.date(byAdding: .day, value: 30, to: fromDate)!)
    }

    let service = EventService(store: store)
    let birthdays = try service.fetchBirthdays(from: fromDate, to: toDate, limit: limit)

    let isTTY = isatty(fileno(stdout)) != 0
    let formatter = try makeFormatter(globalOptions, isTTY: isTTY)
    let output = try formatter.formatBirthdays(birthdays)
    print(output)
  }
}

private func makeFormatter(_ options: GlobalOptions, isTTY: Bool) throws -> any OutputFormatter {
  if let format = options.format {
    let outputFormat = OutputFormat(rawValue: format) ?? (isTTY ? .text : .json)
    return try FormatterFactory.create(format: outputFormat, isTTY: isTTY, noColor: options.noColor)
  }
  return try FormatterFactory.autoDetect(isTTY: isTTY, noColor: options.noColor)
}
