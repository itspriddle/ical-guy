import ArgumentParser

struct GlobalOptions: ParsableArguments {
  @Option(
    name: .long, help: "Output format: json or text (auto-detects based on TTY if not specified).")
  var format: String?

  @Flag(name: .long, help: "Disable colored output.")
  var noColor: Bool = false
}
