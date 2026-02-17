import ArgumentParser

struct GlobalOptions: ParsableArguments {
  @Option(
    name: .long, help: "Output format: json or text (auto-detects based on TTY if not specified).")
  var format: String?

  @Flag(name: .long, help: "Disable colored output.")
  var noColor: Bool = false

  @Option(name: .long, help: "Group output: none, date, or calendar.")
  var groupBy: String?

  @Flag(name: .long, help: "Show dates with no events (implies --group-by date).")
  var showEmptyDates: Bool = false

  @Option(name: .long, help: "Time format string (ICU pattern, e.g. \"HH:mm\" for 24-hour).")
  var timeFormat: String?

  @Option(name: .long, help: "Date format string (ICU pattern, e.g. \"yyyy-MM-dd\").")
  var dateFormat: String?

  @Flag(name: .long, help: "Show event UIDs in text output.")
  var showUid: Bool = false

  @Option(name: .long, help: "Bullet prefix for each event (e.g. \"→ \").")
  var bullet: String?

  @Option(name: .long, help: "Separator between events (e.g. \"---\").")
  var separator: String?

  @Option(name: .long, help: "Indentation for detail lines (default: 4 spaces).")
  var indent: String?

  @Option(name: .long, help: "Truncate notes to N characters (0 = no limit).")
  var truncateNotes: Int?

  @Option(name: .long, help: "Truncate location to N characters (0 = no limit).")
  var truncateLocation: Int?
}
