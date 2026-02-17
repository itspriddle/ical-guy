import Foundation
import Mustache
import XCTest

@testable import ICalGuyKit

// MARK: - TemplateDecorations Unit Tests

final class TemplateDecorationsTests: XCTestCase {
  func testDefaultValues() {
    let deco = TemplateDecorations()
    XCTAssertEqual(deco.bullet, "")
    XCTAssertEqual(deco.separator, "")
    XCTAssertEqual(deco.indent, "    ")
  }

  func testCustomValues() {
    let deco = TemplateDecorations(
      bullet: "- ", separator: "---", indent: "  "
    )
    XCTAssertEqual(deco.bullet, "- ")
    XCTAssertEqual(deco.separator, "---")
    XCTAssertEqual(deco.indent, "  ")
  }

  func testEquatable() {
    let a = TemplateDecorations(bullet: "* ")
    let b = TemplateDecorations(bullet: "* ")
    let c = TemplateDecorations(bullet: "- ")
    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
  }
}

// MARK: - Rendering Tests

final class BulletSeparatorRenderingTests: XCTestCase {
  private let testCalendar = CalendarInfo(
    id: "cal-1",
    title: "Work",
    type: "calDAV",
    source: "iCloud",
    color: "#1BADF8"
  )

  private func makeEvent(
    title: String = "Test Event",
    location: String? = nil
  ) -> CalendarEvent {
    CalendarEvent(
      id: "evt-1",
      title: title,
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: location,
      notes: nil,
      url: nil,
      calendar: testCalendar,
      status: "confirmed"
    )
  }

  func testDefaultBulletIsEmpty() throws {
    let formatter = try TemplateFormatter(colorizer: nil)
    let output = try formatter.formatEvents([makeEvent()])
    let firstLine = output.components(separatedBy: "\n").first!
    // Default: starts with 2-space indent (no bullet prefix)
    XCTAssertTrue(
      firstLine.hasPrefix("  "),
      "Default output should start with spaces, not a bullet"
    )
    XCTAssertFalse(
      firstLine.hasPrefix("- "),
      "Default output should not have a dash bullet"
    )
  }

  func testCustomBullet() throws {
    let deco = TemplateDecorations(bullet: "- ")
    let formatter = try TemplateFormatter(
      colorizer: nil, decorations: deco
    )
    let output = try formatter.formatEvents([makeEvent()])
    let firstLine = output.components(separatedBy: "\n").first!
    XCTAssertTrue(
      firstLine.hasPrefix("- "),
      "Output should start with custom bullet '- '"
    )
  }

  func testArrowBullet() throws {
    let deco = TemplateDecorations(bullet: "\u{2192} ")
    let formatter = try TemplateFormatter(
      colorizer: nil, decorations: deco
    )
    let output = try formatter.formatEvents([makeEvent()])
    let firstLine = output.components(separatedBy: "\n").first!
    XCTAssertTrue(
      firstLine.hasPrefix("\u{2192} "),
      "Output should start with arrow bullet"
    )
  }

  func testCustomIndent() throws {
    let options = TextFormatterOptions(showLocation: true)
    let deco = TemplateDecorations(indent: ">> ")
    let formatter = try TemplateFormatter(
      options: options, colorizer: nil, decorations: deco
    )
    let event = makeEvent(location: "Room A")
    let output = try formatter.formatEvents([event])
    XCTAssertTrue(
      output.contains(">> Location:"),
      "Detail lines should use custom indent"
    )
  }

  func testDefaultIndentIsFourSpaces() throws {
    let options = TextFormatterOptions(showLocation: true)
    let formatter = try TemplateFormatter(
      options: options, colorizer: nil
    )
    let event = makeEvent(location: "Room A")
    let output = try formatter.formatEvents([event])
    let lines = output.components(separatedBy: "\n")
    let locationLine = lines.first { $0.contains("Location:") }
    XCTAssertNotNil(locationLine)
    XCTAssertTrue(
      locationLine!.hasPrefix("    "),
      "Default detail indent should be 4 spaces"
    )
  }

  func testCustomSeparatorBetweenEvents() throws {
    let deco = TemplateDecorations(separator: "---")
    let formatter = try TemplateFormatter(
      colorizer: nil, decorations: deco
    )
    let events = [
      makeEvent(title: "Event A"),
      makeEvent(title: "Event B"),
    ]
    let output = try formatter.formatEvents(events)
    XCTAssertTrue(
      output.contains("---"),
      "Output should contain separator between events"
    )
    // Verify separator is between events
    let parts = output.components(separatedBy: "---")
    XCTAssertEqual(
      parts.count, 2,
      "Separator should appear once between two events"
    )
    XCTAssertTrue(parts[0].contains("Event A"))
    XCTAssertTrue(parts[1].contains("Event B"))
  }

  func testDefaultSeparatorIsEmpty() throws {
    let formatter = try TemplateFormatter(colorizer: nil)
    let events = [
      makeEvent(title: "Event A"),
      makeEvent(title: "Event B"),
    ]
    let output = try formatter.formatEvents(events)
    // Events should be separated by a single newline (no blank line)
    XCTAssertFalse(
      output.contains("\n\n"),
      "Default separator should not produce blank lines between events"
    )
  }

  func testSeparatorWithDateGrouping() throws {
    let deco = TemplateDecorations(separator: "~~~")
    let grouping = GroupingContext(mode: .date)
    let formatter = try TemplateFormatter(
      colorizer: nil, grouping: grouping, decorations: deco
    )
    let events = [
      makeEvent(title: "Event A"),
      makeEvent(title: "Event B"),
    ]
    let output = try formatter.formatEvents(events)
    XCTAssertTrue(
      output.contains("~~~"),
      "Separator should work with date grouping"
    )
  }

  func testSeparatorWithCalendarGrouping() throws {
    let deco = TemplateDecorations(separator: "***")
    let grouping = GroupingContext(mode: .calendar)
    let formatter = try TemplateFormatter(
      colorizer: nil, grouping: grouping, decorations: deco
    )
    let events = [
      makeEvent(title: "Event A"),
      makeEvent(title: "Event B"),
    ]
    let output = try formatter.formatEvents(events)
    XCTAssertTrue(
      output.contains("***"),
      "Separator should work with calendar grouping"
    )
  }

  func testAllDecorationsTogetherFlat() throws {
    let options = TextFormatterOptions(showLocation: true)
    let deco = TemplateDecorations(
      bullet: "* ", separator: "---", indent: "  "
    )
    let formatter = try TemplateFormatter(
      options: options, colorizer: nil, decorations: deco
    )
    let events = [
      makeEvent(title: "First", location: "Room 1"),
      makeEvent(title: "Second", location: "Room 2"),
    ]
    let output = try formatter.formatEvents(events)

    // Verify bullet
    let lines = output.components(separatedBy: "\n")
    let eventLines = lines.filter { $0.contains("First") || $0.contains("Second") }
    for line in eventLines {
      XCTAssertTrue(
        line.hasPrefix("* "),
        "Event lines should start with bullet: \(line)"
      )
    }

    // Verify separator
    XCTAssertTrue(output.contains("---"))

    // Verify indent
    XCTAssertTrue(output.contains("  Location:"))
  }
}

// MARK: - Config Integration Tests

final class BulletSeparatorConfigTests: XCTestCase {
  func testUserConfigBulletField() {
    let config = UserConfig(bullet: "- ")
    XCTAssertEqual(config.bullet, "- ")
  }

  func testUserConfigSeparatorField() {
    let config = UserConfig(separator: "---")
    XCTAssertEqual(config.separator, "---")
  }

  func testUserConfigIndentField() {
    let config = UserConfig(indent: "  ")
    XCTAssertEqual(config.indent, "  ")
  }

  func testUserConfigDefaultsNil() {
    let config = UserConfig()
    XCTAssertNil(config.bullet)
    XCTAssertNil(config.separator)
    XCTAssertNil(config.indent)
  }

  func testRuntimeOptionsDecorationsFromConfig() throws {
    let config = UserConfig(
      bullet: "* ", separator: "---", indent: "  "
    )
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: config, cli: cli)
    XCTAssertEqual(opts.decorations.bullet, "* ")
    XCTAssertEqual(opts.decorations.separator, "---")
    XCTAssertEqual(opts.decorations.indent, "  ")
  }

  func testRuntimeOptionsDecorationsDefaults() throws {
    let cli = CLIOptions()
    let opts = try RuntimeOptions.resolve(config: nil, cli: cli)
    XCTAssertEqual(opts.decorations.bullet, "")
    XCTAssertEqual(opts.decorations.separator, "")
    XCTAssertEqual(opts.decorations.indent, "    ")
  }

  func testFormatterFactoryPassesDecorations() throws {
    let deco = TemplateDecorations(bullet: "\u{2192} ")
    let formatter = try FormatterFactory.create(
      format: .text, isTTY: true, noColor: true,
      decorations: deco
    )
    // Verify the formatter is a TemplateFormatter (text format)
    XCTAssertTrue(formatter is TemplateFormatter)
    // Verify bullet is applied by checking output
    let event = CalendarEvent(
      id: "e1",
      title: "Test",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: nil,
      notes: nil,
      url: nil,
      calendar: CalendarInfo(
        id: "c1", title: "Cal", type: "calDAV",
        source: "iCloud", color: "#000"
      ),
      status: "confirmed"
    )
    let output = try formatter.formatEvents([event])
    XCTAssertTrue(output.hasPrefix("\u{2192} "))
  }

  func testDecorationsAvailableInCustomTemplate() throws {
    let deco = TemplateDecorations(
      bullet: ">> ", separator: "===", indent: ".."
    )
    let template = try MustacheTemplate(
      string: "{{{bullet}}}{{title}} | indent={{{indent}}}"
    )
    let formatter = try TemplateFormatter(
      colorizer: nil, eventTemplate: template, decorations: deco
    )
    let event = CalendarEvent(
      id: "e1",
      title: "Meeting",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: nil,
      notes: nil,
      url: nil,
      calendar: CalendarInfo(
        id: "c1", title: "Cal", type: "calDAV",
        source: "iCloud", color: "#000"
      ),
      status: "confirmed"
    )
    let output = try formatter.formatEvents([event])
    XCTAssertEqual(output, ">> Meeting | indent=..")
  }
}
