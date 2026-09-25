import Foundation
import XCTest

@testable import ICalGuyKit

// MARK: - Notes Template Rendering Tests

final class NotesDisplayRenderingTests: XCTestCase {
  private let testCalendar = CalendarInfo(
    id: "cal-1",
    title: "Work",
    type: "calDAV",
    source: "iCloud",
    color: "#1BADF8"
  )

  private func makeEvent(notes: String?) -> CalendarEvent {
    CalendarEvent(
      id: "evt-123",
      title: "Test Event",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: nil,
      notes: notes,
      url: nil,
      calendar: testCalendar,
      status: "confirmed"
    )
  }

  private func render(
    notes: String?,
    showNotes: Bool = true,
    truncation: TruncationLimits = TruncationLimits()
  ) throws -> String {
    let formatter = try TemplateFormatter(
      options: TextFormatterOptions(showNotes: showNotes),
      colorizer: nil,
      truncation: truncation
    )
    return try formatter.formatEvents([makeEvent(notes: notes)])
  }

  func testNotesHiddenByDefault() throws {
    let formatter = try TemplateFormatter(colorizer: nil)
    let output = try formatter.formatEvents([makeEvent(notes: "Bring snacks")])
    XCTAssertFalse(output.contains("Notes:"))
    XCTAssertFalse(output.contains("Bring snacks"))
  }

  func testNotesShownWhenEnabled() throws {
    let output = try render(notes: "Bring snacks")
    XCTAssertTrue(output.contains("Notes:"))
    XCTAssertTrue(output.contains("      Bring snacks"))
  }

  func testNotesHiddenWhenExplicitlyDisabled() throws {
    let output = try render(notes: "Bring snacks", showNotes: false)
    XCTAssertFalse(output.contains("Notes:"))
  }

  func testNoNotesLabelWhenNotesNilOrEmpty() throws {
    XCTAssertFalse(try render(notes: nil).contains("Notes:"))
    XCTAssertFalse(try render(notes: "").contains("Notes:"))
  }

  func testMultiLineNotesAreIndented() throws {
    let output = try render(notes: "Line one\n\nLine two\r\nLine three\n")
    let lines = output.components(separatedBy: "\n")
    XCTAssertTrue(lines.contains("      Line one"))
    XCTAssertTrue(lines.contains("      Line two"))
    XCTAssertTrue(lines.contains("      Line three"))
    for line in lines {
      XCTAssertFalse(line.hasSuffix(" "), "Line has trailing whitespace: '\(line)'")
    }
  }

  func testNotesAreNotHTMLEscaped() throws {
    let output = try render(notes: "<b>Booked by</b> A & B")
    XCTAssertTrue(output.contains("<b>Booked by</b> A & B"))
  }

  func testNotesRespectTruncation() throws {
    let output = try render(
      notes: "This is a long note", truncation: TruncationLimits(notes: 10)
    )
    XCTAssertTrue(output.contains("      This is..."))
    XCTAssertFalse(output.contains("long note"))
  }

  func testNotesAppearBeforeRecurrenceAndUid() throws {
    let event = CalendarEvent(
      id: "evt-789",
      title: "Standup",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: nil,
      notes: "Agenda",
      url: nil,
      calendar: testCalendar,
      recurrence: RecurrenceInfo(isRecurring: true, description: "Every weekday"),
      status: "confirmed"
    )
    let formatter = try TemplateFormatter(
      options: TextFormatterOptions(showNotes: true, showUid: true), colorizer: nil
    )
    let output = try formatter.formatEvents([event])
    let lines = output.components(separatedBy: "\n")
    let notesIndex = try XCTUnwrap(lines.firstIndex { $0.contains("Notes:") })
    let recursIndex = try XCTUnwrap(lines.firstIndex { $0.contains("Recurs:") })
    let uidIndex = try XCTUnwrap(lines.firstIndex { $0.contains("UID:") })
    XCTAssertLessThan(notesIndex, recursIndex)
    XCTAssertLessThan(recursIndex, uidIndex)
  }
}
