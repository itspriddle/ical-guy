import ArgumentParser
import Foundation
import ICalGuyKit

struct WeekCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "week",
    abstract: "Print the week number according to Calendar.app."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Argument(help: "Date in YYYY-MM-DD format (default: today).")
  var date: String?

  @Option(name: [.customShort("N"), .long], help: "Offset forward by N weeks.")
  var next: Int?

  @Option(name: [.customShort("P"), .long], help: "Offset backward by N weeks.")
  var prev: Int?

  @Flag(name: .long, help: "Print the start date (Sunday) of the week.")
  var startDate: Bool = false

  @Flag(name: .long, help: "Print the end date (Saturday) of the week.")
  var endDate: Bool = false

  @Flag(name: .long, help: "Don't zero-pad single digit week numbers.")
  var noPad: Bool = false

  func validate() throws {
    if next != nil && prev != nil {
      throw ValidationError("Cannot use --next and --prev together.")
    }
    if startDate && endDate {
      throw ValidationError("Cannot use --start-date and --end-date together.")
    }
  }

  func run() throws {
    let dateParser = DateParser()
    let baseDate: Date
    if let dateStr = date {
      baseDate = try dateParser.parse(dateStr)
    } else {
      baseDate = Date()
    }

    let calculator = WeekCalculator()

    let targetDate: Date
    if let n = next {
      targetDate = calculator.calendar.date(
        byAdding: .weekOfYear, value: n, to: baseDate)!
    } else if let n = prev {
      targetDate = calculator.calendar.date(
        byAdding: .weekOfYear, value: -n, to: baseDate)!
    } else {
      targetDate = baseDate
    }

    let info = calculator.weekInfo(for: targetDate)

    let isTTY = isatty(fileno(stdout)) != 0
    if resolveJSON(globalOptions.format, isTTY: isTTY) {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      dateFormatter.calendar = calculator.calendar
      encoder.dateEncodingStrategy = .formatted(dateFormatter)
      let data = try encoder.encode(info)
      print(String(data: data, encoding: .utf8)!)
    } else if startDate {
      print(formatDateString(info.startDate, calendar: calculator.calendar))
    } else if endDate {
      print(formatDateString(info.endDate, calendar: calculator.calendar))
    } else {
      print(noPad ? "\(info.week)" : String(format: "%02d", info.week))
    }
  }
}

private func resolveJSON(_ format: String?, isTTY: Bool) -> Bool {
  if let format { return format == "json" }
  return !isTTY
}

private func formatDateString(_ date: Date, calendar: Calendar) -> String {
  let c = calendar.dateComponents([.year, .month, .day], from: date)
  return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}
