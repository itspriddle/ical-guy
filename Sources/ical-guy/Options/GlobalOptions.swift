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
}
