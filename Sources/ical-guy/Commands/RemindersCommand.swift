import ArgumentParser
import Foundation
import ICalGuyKit

struct RemindersCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "reminders",
    abstract: "Query and list reminders.",
    subcommands: [
      RemindersListCommand.self,
      RemindersListsCommand.self,
    ],
    defaultSubcommand: RemindersListCommand.self
  )
}

// MARK: - reminders list

struct RemindersListCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "List reminders."
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Flag(name: .long, help: "Show completed reminders.")
  var completed: Bool = false

  @Flag(name: .long, help: "Show all reminders (completed and incomplete).")
  var all: Bool = false

  @Option(name: .long, help: "Start date for due date filter (ISO 8601, 'today', etc.).")
  var from: String?

  @Option(name: .long, help: "End date for due date filter (same formats as --from).")
  var to: String?

  @Option(name: .long, help: "Only include these lists (comma-separated names).")
  var includeLists: String?

  @Option(name: .long, help: "Exclude these lists (comma-separated names).")
  var excludeLists: String?

  @Option(name: .long, help: "Maximum number of reminders to output.")
  var limit: Int?

  @Option(name: .long, help: "Sort by: dueDate, priority, title, creationDate.")
  var sortBy: String?

  func run() async throws {
    let store = LiveReminderStore()
    try await store.requestAccess()

    let filter: ReminderFilter
    if all {
      filter = .all
    } else if completed {
      filter = .completed
    } else {
      filter = .incomplete
    }

    let dateParser = DateParser()
    let startDate: Date? = try from.map { try dateParser.parse($0) }
    let endDate: Date? = try to.map { try dateParser.parse($0) }

    let sortField: ReminderSortField
    if let sortBy {
      guard let field = ReminderSortField(rawValue: sortBy) else {
        throw ValidationError(
          "Invalid sort field '\(sortBy)'. Use: dueDate, priority, title, creationDate.")
      }
      sortField = field
    } else {
      sortField = .dueDate
    }

    let options = ReminderServiceOptions(
      filter: filter,
      startDate: startDate,
      endDate: endDate,
      includeLists: parseCSV(includeLists),
      excludeLists: parseCSV(excludeLists),
      limit: limit,
      sortBy: sortField
    )

    let service = ReminderService(store: store)
    let reminders = try await service.fetchReminders(options: options)

    let isTTY = isatty(fileno(stdout)) != 0
    let grouping = makeReminderGrouping(globalOptions)
    let formatter = try makeFormatter(globalOptions, isTTY: isTTY, grouping: grouping)
    let output = try formatter.formatReminders(reminders)
    print(output)
  }
}

// MARK: - reminders lists

struct RemindersListsCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "lists",
    abstract: "List available reminder lists."
  )

  @OptionGroup var globalOptions: GlobalOptions

  func run() async throws {
    let store = LiveReminderStore()
    try await store.requestAccess()

    let service = ReminderService(store: store)
    let lists = try service.fetchReminderLists()

    let isTTY = isatty(fileno(stdout)) != 0
    let formatter = try makeFormatter(globalOptions, isTTY: isTTY)
    let output = try formatter.formatReminderLists(lists)
    print(output)
  }
}

// MARK: - Helpers

private func parseCSV(_ value: String?) -> [String]? {
  value?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
}

private func makeReminderGrouping(_ options: GlobalOptions) -> GroupingContext {
  let mode: GroupingMode
  if let groupBy = options.groupBy, let parsed = GroupingMode(rawValue: groupBy) {
    mode = parsed
  } else {
    mode = .none
  }
  return GroupingContext(mode: mode)
}

private func makeFormatter(
  _ options: GlobalOptions, isTTY: Bool, grouping: GroupingContext = GroupingContext()
) throws -> any OutputFormatter {
  if let format = options.format {
    let outputFormat = OutputFormat(rawValue: format) ?? (isTTY ? .text : .json)
    return try FormatterFactory.create(
      format: outputFormat, isTTY: isTTY, noColor: options.noColor, grouping: grouping
    )
  }
  return try FormatterFactory.autoDetect(
    isTTY: isTTY, noColor: options.noColor, grouping: grouping
  )
}
