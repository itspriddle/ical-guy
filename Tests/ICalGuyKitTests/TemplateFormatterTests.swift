import Foundation
import Mustache
import XCTest

@testable import ICalGuyKit

// MARK: - Test Fixtures

private let testCalendar = CalendarInfo(
  id: "cal-1",
  title: "Work",
  type: "calDAV",
  source: "iCloud",
  color: "#1BADF8"
)

private let personalCalendar = CalendarInfo(
  id: "cal-2",
  title: "Personal",
  type: "local",
  source: "On My Mac",
  color: "#FF2D55"
)

private func makeEvent(
  id: String = "evt-1",
  title: String = "Team Standup",
  start: TimeInterval = 1_710_500_400,  // 2024-03-15 14:00 UTC
  end: TimeInterval = 1_710_502_200,  // 2024-03-15 14:30 UTC
  isAllDay: Bool = false,
  location: String? = nil,
  notes: String? = nil,
  url: String? = nil,
  meetingUrl: String? = nil,
  calendar: CalendarInfo = testCalendar,
  attendees: [Attendee] = [],
  organizer: Organizer? = nil,
  recurrence: RecurrenceInfo = RecurrenceInfo(isRecurring: false, description: nil),
  status: String = "confirmed",
  availability: String = "busy"
) -> CalendarEvent {
  CalendarEvent(
    id: id,
    title: title,
    startDate: Date(timeIntervalSince1970: start),
    endDate: Date(timeIntervalSince1970: end),
    isAllDay: isAllDay,
    location: location,
    notes: notes,
    url: url,
    meetingUrl: meetingUrl,
    calendar: calendar,
    attendees: attendees,
    organizer: organizer,
    recurrence: recurrence,
    status: status,
    availability: availability
  )
}

// MARK: - Event Rendering (No Color)

final class TemplateFormatterEventTests: XCTestCase {
  func testBasicEventNoColor() throws {
    let formatter = try TemplateFormatter()
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("[Work]"))
    XCTAssertTrue(result.contains(":"))
  }

  func testAllDayEventNoColor() throws {
    let formatter = try TemplateFormatter()
    let event = makeEvent(isAllDay: true)
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("All day"))
    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("[Work]"))
  }

  func testEventWithLocationNoColor() throws {
    let formatter = try TemplateFormatter()
    let event = makeEvent(location: "Conference Room B")
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("Location:"))
    XCTAssertTrue(result.contains("Conference Room B"))
  }

  func testEventWithMeetingUrlNoColor() throws {
    let formatter = try TemplateFormatter()
    let event = makeEvent(meetingUrl: "https://zoom.us/j/123456")
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("Meeting:"))
    XCTAssertTrue(result.contains("https://zoom.us/j/123456"))
  }

  func testEventWithAttendeesNoColor() throws {
    let attendees = [
      Attendee(
        name: "Alice Smith", email: "alice@example.com",
        status: .accepted, role: .required, isCurrentUser: false
      ),
      Attendee(
        name: "Bob Jones", email: "bob@example.com",
        status: .tentative, role: .optional, isCurrentUser: true
      ),
    ]
    let formatter = try TemplateFormatter()
    let event = makeEvent(attendees: attendees)
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Attendees:"))
    XCTAssertTrue(result.contains("Alice Smith"))
    XCTAssertTrue(result.contains("alice@example.com"))
    XCTAssertTrue(result.contains("Bob Jones"))
    XCTAssertTrue(result.contains("(you)"))
  }

  func testEventWithRecurrenceNoColor() throws {
    let recurrence = RecurrenceInfo(isRecurring: true, description: "Every weekday")
    let formatter = try TemplateFormatter()
    let event = makeEvent(recurrence: recurrence)
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("Recurs:"))
    XCTAssertTrue(result.contains("Every weekday"))
  }

  func testFullEventNoColor() throws {
    let attendees = [
      Attendee(
        name: "Alice Smith", email: "alice@example.com",
        status: .accepted, role: .required, isCurrentUser: false
      ),
      Attendee(
        name: "Bob Jones", email: "bob@example.com",
        status: .tentative, role: .optional, isCurrentUser: true
      ),
    ]
    let recurrence = RecurrenceInfo(isRecurring: true, description: "Every weekday")
    let formatter = try TemplateFormatter()
    let event = makeEvent(
      location: "Conference Room B",
      meetingUrl: "https://zoom.us/j/123456",
      attendees: attendees,
      recurrence: recurrence
    )
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("[Work]"))
    XCTAssertTrue(result.contains("Location:"))
    XCTAssertTrue(result.contains("Conference Room B"))
    XCTAssertTrue(result.contains("Meeting:"))
    XCTAssertTrue(result.contains("https://zoom.us/j/123456"))
    XCTAssertTrue(result.contains("Attendees:"))
    XCTAssertTrue(result.contains("Alice Smith"))
    XCTAssertTrue(result.contains("Recurs:"))
    XCTAssertTrue(result.contains("Every weekday"))
  }

  func testEmptyEventsNoColor() throws {
    let formatter = try TemplateFormatter()
    let result = try formatter.formatEvents([])
    XCTAssertEqual(result, "No events.")
  }

  func testMultipleEventsNoColor() throws {
    let events = [
      makeEvent(id: "evt-1", title: "Meeting 1"),
      makeEvent(id: "evt-2", title: "Meeting 2"),
    ]
    let formatter = try TemplateFormatter()
    let result = try formatter.formatEvents(events)

    XCTAssertTrue(result.contains("Meeting 1"))
    XCTAssertTrue(result.contains("Meeting 2"))
  }
}

// MARK: - Event Rendering With Color

final class TemplateFormatterColorTests: XCTestCase {
  private let colorizer = ANSIColorizer(capability: .truecolor)

  func testBasicEventWithColor() throws {
    let formatter = try TemplateFormatter(colorizer: colorizer)
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("[Work]"))
    // Should contain ANSI escape codes
    XCTAssertTrue(result.contains("\u{1B}["))
  }

  func testFullEventWithColor() throws {
    let attendees = [
      Attendee(
        name: "Alice Smith", email: "alice@example.com",
        status: .accepted, role: .required, isCurrentUser: false
      )
    ]
    let recurrence = RecurrenceInfo(isRecurring: true, description: "Weekly")
    let formatter = try TemplateFormatter(colorizer: colorizer)
    let event = makeEvent(
      location: "Room A",
      meetingUrl: "https://meet.google.com/abc",
      attendees: attendees,
      recurrence: recurrence
    )
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("Room A"))
    XCTAssertTrue(result.contains("https://meet.google.com/abc"))
    XCTAssertTrue(result.contains("Alice Smith"))
    XCTAssertTrue(result.contains("Weekly"))
    XCTAssertTrue(result.contains("\u{1B}["))
  }

  func testAllDayEventWithColor() throws {
    let formatter = try TemplateFormatter(colorizer: colorizer)
    let event = makeEvent(isAllDay: true)
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("All day"))
    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("\u{1B}["))
  }
}

// MARK: - TextFormatterOptions

final class TemplateFormatterOptionsTests: XCTestCase {
  func testHideCalendar() throws {
    let options = TextFormatterOptions(showCalendar: false)
    let formatter = try TemplateFormatter(options: options)
    let event = makeEvent()
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertFalse(result.contains("[Work]"))
  }

  func testHideLocation() throws {
    let options = TextFormatterOptions(showLocation: false)
    let formatter = try TemplateFormatter(options: options)
    let event = makeEvent(location: "Room A")
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertFalse(result.contains("Location:"))
    XCTAssertFalse(result.contains("Room A"))
  }

  func testHideAttendees() throws {
    let options = TextFormatterOptions(showAttendees: false)
    let attendees = [
      Attendee(
        name: "Alice", email: "a@b.com",
        status: .accepted, role: .required, isCurrentUser: false
      )
    ]
    let formatter = try TemplateFormatter(options: options)
    let event = makeEvent(attendees: attendees)
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertFalse(result.contains("Attendees:"))
    XCTAssertFalse(result.contains("Alice"))
  }

  func testHideMeetingUrl() throws {
    let options = TextFormatterOptions(showMeetingUrl: false)
    let formatter = try TemplateFormatter(options: options)
    let event = makeEvent(meetingUrl: "https://zoom.us/j/123")
    let result = try formatter.formatEvents([event])

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertFalse(result.contains("Meeting:"))
    XCTAssertFalse(result.contains("https://zoom.us/j/123"))
  }
}

// MARK: - Grouping

final class TemplateFormatterGroupingTests: XCTestCase {
  func testDateGroupingNoColor() throws {
    let grouping = GroupingContext(mode: .date)
    let formatter = try TemplateFormatter(grouping: grouping)
    let events = [
      makeEvent(id: "evt-1", title: "Meeting 1"),
      makeEvent(id: "evt-2", title: "Meeting 2"),
    ]
    let result = try formatter.formatEvents(events)

    XCTAssertTrue(result.contains("Meeting 1"))
    XCTAssertTrue(result.contains("Meeting 2"))
    // Date header should be present (first line)
    let firstLine = String(result.split(separator: "\n")[0])
    XCTAssertTrue(firstLine.contains("2024"))
  }

  func testCalendarGroupingNoColor() throws {
    let grouping = GroupingContext(mode: .calendar)
    let events = [
      makeEvent(id: "evt-1", title: "Work Meeting", calendar: testCalendar),
      makeEvent(
        id: "evt-2", title: "Gym", calendar: personalCalendar
      ),
    ]
    let formatter = try TemplateFormatter(grouping: grouping)
    let result = try formatter.formatEvents(events)

    XCTAssertTrue(result.contains("Work"))
    XCTAssertTrue(result.contains("Personal"))
    XCTAssertTrue(result.contains("Work Meeting"))
    XCTAssertTrue(result.contains("Gym"))
  }

  func testDateGroupingWithColor() throws {
    let colorizer = ANSIColorizer(capability: .truecolor)
    let grouping = GroupingContext(mode: .date)
    let formatter = try TemplateFormatter(
      colorizer: colorizer, grouping: grouping
    )
    let events = [makeEvent()]
    let result = try formatter.formatEvents(events)

    XCTAssertTrue(result.contains("Team Standup"))
    XCTAssertTrue(result.contains("\u{1B}["))
  }

  func testEmptyDateGroupShowEmpty() throws {
    let from = Date(timeIntervalSince1970: 1_710_460_800)  // 2024-03-15
    let to = Date(timeIntervalSince1970: 1_710_547_200)  // 2024-03-16
    let grouping = GroupingContext(
      mode: .date,
      showEmptyDates: true,
      dateRange: DateRange(from: from, to: to)
    )
    let formatter = try TemplateFormatter(grouping: grouping)
    let result = try formatter.formatEvents([])

    XCTAssertTrue(result.contains("No events."))
  }
}

// MARK: - Group Header Templates

final class TemplateFormatterGroupHeaderTests: XCTestCase {
  func testCustomDateHeaderTemplate() throws {
    let grouping = GroupingContext(mode: .date)
    let customTemplate = try MustacheTemplate(string: "== {{formattedDate}} ==")
    let formatter = try TemplateFormatter(
      grouping: grouping, dateHeaderTemplate: customTemplate
    )
    let events = [makeEvent()]
    let result = try formatter.formatEvents(events)

    // Verify the custom wrapper is present (date varies by timezone)
    XCTAssertTrue(result.contains("== "))
    XCTAssertTrue(result.contains(" =="))
    // First line should be the custom header
    let firstLine = String(result.split(separator: "\n")[0])
    XCTAssertTrue(firstLine.hasPrefix("== "))
    XCTAssertTrue(firstLine.hasSuffix(" =="))
  }

  func testCustomCalendarHeaderTemplate() throws {
    let grouping = GroupingContext(mode: .calendar)
    let customTemplate = try MustacheTemplate(string: "[ {{title}} ]")
    let formatter = try TemplateFormatter(
      grouping: grouping, calendarHeaderTemplate: customTemplate
    )
    let events = [makeEvent()]
    let result = try formatter.formatEvents(events)

    XCTAssertTrue(result.contains("[ Work ]"))
  }

  func testDateHeaderWithColor() throws {
    let colorizer = ANSIColorizer(capability: .truecolor)
    let grouping = GroupingContext(mode: .date)
    let formatter = try TemplateFormatter(
      colorizer: colorizer, grouping: grouping
    )
    let events = [makeEvent()]
    let result = try formatter.formatEvents(events)

    // Should contain bold escape codes for the date header
    XCTAssertTrue(result.contains("\u{1B}[1m"))
    XCTAssertTrue(result.contains("Team Standup"))
  }

  func testCalendarHeaderWithColor() throws {
    let colorizer = ANSIColorizer(capability: .truecolor)
    let grouping = GroupingContext(mode: .calendar)
    let formatter = try TemplateFormatter(
      colorizer: colorizer, grouping: grouping
    )
    let events = [makeEvent()]
    let result = try formatter.formatEvents(events)

    // Should have both bold and color escape codes around "Work"
    let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
    let header = String(lines[0])
    XCTAssertTrue(header.contains("Work"))
    XCTAssertTrue(header.contains("\u{1B}[1m"))  // bold
    XCTAssertTrue(header.contains("\u{1B}[38;2;"))  // truecolor
  }

  func testShowEmptyDatesWithTemplatedHeaders() throws {
    let from = Date(timeIntervalSince1970: 1_710_460_800)  // 2024-03-15
    let to = Date(timeIntervalSince1970: 1_710_547_200)  // 2024-03-16
    let grouping = GroupingContext(
      mode: .date,
      showEmptyDates: true,
      dateRange: DateRange(from: from, to: to)
    )
    let formatter = try TemplateFormatter(grouping: grouping)
    let result = try formatter.formatEvents([])

    XCTAssertTrue(result.contains("No events."))
  }

  func testMultipleCalendarGroupHeaders() throws {
    let grouping = GroupingContext(mode: .calendar)
    let events = [
      makeEvent(id: "evt-1", title: "Work Meeting", calendar: testCalendar),
      makeEvent(id: "evt-2", title: "Gym", calendar: personalCalendar),
    ]
    let formatter = try TemplateFormatter(grouping: grouping)
    let result = try formatter.formatEvents(events)

    XCTAssertTrue(result.contains("Work"))
    XCTAssertTrue(result.contains("Personal"))
    XCTAssertTrue(result.contains("Work Meeting"))
    XCTAssertTrue(result.contains("Gym"))
  }

  func testDateHeaderNoColorMatchesExpected() throws {
    let grouping = GroupingContext(mode: .date)
    let events = [makeEvent()]
    let formatter = try TemplateFormatter(grouping: grouping)
    let result = try formatter.formatEvents(events)

    let firstLine = String(result.split(separator: "\n")[0])
    XCTAssertTrue(
      firstLine.contains("2024"),
      "Date header should contain year: \(firstLine)"
    )
  }

  func testCalendarHeaderNoColorMatchesExpected() throws {
    let grouping = GroupingContext(mode: .calendar)
    let events = [makeEvent()]
    let formatter = try TemplateFormatter(grouping: grouping)
    let result = try formatter.formatEvents(events)

    let firstLine = result.split(separator: "\n", omittingEmptySubsequences: false)[0]
    XCTAssertEqual(String(firstLine), "Work")
  }

  func testUngroupedIgnoresHeaderTemplates() throws {
    let customDate = try MustacheTemplate(string: "CUSTOM DATE")
    let customCal = try MustacheTemplate(string: "CUSTOM CAL")
    let formatter = try TemplateFormatter(
      dateHeaderTemplate: customDate, calendarHeaderTemplate: customCal
    )
    let events = [makeEvent()]
    let result = try formatter.formatEvents(events)

    XCTAssertFalse(result.contains("CUSTOM DATE"))
    XCTAssertFalse(result.contains("CUSTOM CAL"))
  }
}
