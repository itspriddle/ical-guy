import Foundation
import Mustache
import XCTest

@testable import ICalGuyKit

final class EventTemplateContextTests: XCTestCase {
  // MARK: - Test Fixtures

  private let testCalendar = CalendarInfo(
    id: "cal-1",
    title: "Work",
    type: "calDAV",
    source: "iCloud",
    color: "#1BADF8"
  )

  private var fullEvent: CalendarEvent {
    CalendarEvent(
      id: "evt-123",
      title: "Team Standup",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),  // 2024-03-15 14:00 UTC
      endDate: Date(timeIntervalSince1970: 1_710_502_200),  // 2024-03-15 14:30 UTC
      isAllDay: false,
      location: "Conference Room B",
      notes: "Weekly sync meeting",
      url: "https://calendar.example.com/evt-123",
      meetingUrl: "https://zoom.us/j/123456",
      calendar: testCalendar,
      attendees: [
        Attendee(
          name: "Alice Smith", email: "alice@example.com",
          status: .accepted, role: .required, isCurrentUser: false
        ),
        Attendee(
          name: "Bob Jones", email: "bob@example.com",
          status: .tentative, role: .optional, isCurrentUser: true
        ),
      ],
      organizer: Organizer(name: "Alice Smith", email: "alice@example.com"),
      recurrence: RecurrenceInfo(isRecurring: true, description: "Every weekday"),
      status: "confirmed",
      availability: "busy",
      timeZone: "America/New_York"
    )
  }

  private var minimalEvent: CalendarEvent {
    CalendarEvent(
      id: "evt-456",
      title: "Quick Chat",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: nil,
      notes: nil,
      url: nil,
      calendar: testCalendar,
      status: "none"
    )
  }

  private var allDayEvent: CalendarEvent {
    CalendarEvent(
      id: "evt-789",
      title: "Company Holiday",
      startDate: Date(timeIntervalSince1970: 1_710_460_800),  // 2024-03-15 00:00 UTC
      endDate: Date(timeIntervalSince1970: 1_710_547_200),  // 2024-03-16 00:00 UTC
      isAllDay: true,
      location: nil,
      notes: nil,
      url: nil,
      calendar: testCalendar,
      status: "confirmed"
    )
  }

  // MARK: - Scalar Fields

  func testScalarFieldsAreMapped() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: fullEvent)

    XCTAssertEqual(ctx["title"] as? String, "Team Standup")
    XCTAssertEqual(ctx["location"] as? String, "Conference Room B")
    XCTAssertEqual(ctx["notes"] as? String, "Weekly sync meeting")
    XCTAssertEqual(ctx["url"] as? String, "https://calendar.example.com/evt-123")
    XCTAssertEqual(ctx["meetingUrl"] as? String, "https://zoom.us/j/123456")
    XCTAssertEqual(ctx["status"] as? String, "confirmed")
    XCTAssertEqual(ctx["availability"] as? String, "busy")
    XCTAssertEqual(ctx["timeZone"] as? String, "America/New_York")
    XCTAssertEqual(ctx["id"] as? String, "evt-123")
  }

  func testNilScalarFieldsDefaultToEmptyString() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: minimalEvent)

    XCTAssertEqual(ctx["location"] as? String, "")
    XCTAssertEqual(ctx["notes"] as? String, "")
    XCTAssertEqual(ctx["url"] as? String, "")
    XCTAssertEqual(ctx["meetingUrl"] as? String, "")
    XCTAssertEqual(ctx["timeZone"] as? String, "")
  }

  // MARK: - Boolean Convenience Flags

  func testBooleanFlagsForFullEvent() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: fullEvent)

    XCTAssertEqual(ctx["hasLocation"] as? Bool, true)
    XCTAssertEqual(ctx["hasNotes"] as? Bool, true)
    XCTAssertEqual(ctx["hasUrl"] as? Bool, true)
    XCTAssertEqual(ctx["hasMeetingUrl"] as? Bool, true)
    XCTAssertEqual(ctx["hasAttendees"] as? Bool, true)
    XCTAssertEqual(ctx["hasOrganizer"] as? Bool, true)
    XCTAssertEqual(ctx["isAllDay"] as? Bool, false)
    XCTAssertEqual(ctx["isRecurring"] as? Bool, true)
  }

  func testBooleanFlagsForMinimalEvent() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: minimalEvent)

    XCTAssertEqual(ctx["hasLocation"] as? Bool, false)
    XCTAssertEqual(ctx["hasNotes"] as? Bool, false)
    XCTAssertEqual(ctx["hasUrl"] as? Bool, false)
    XCTAssertEqual(ctx["hasMeetingUrl"] as? Bool, false)
    XCTAssertEqual(ctx["hasAttendees"] as? Bool, false)
    XCTAssertEqual(ctx["hasOrganizer"] as? Bool, false)
    XCTAssertEqual(ctx["isAllDay"] as? Bool, false)
    XCTAssertEqual(ctx["isRecurring"] as? Bool, false)
  }

  func testBooleanFlagsForAllDayEvent() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: allDayEvent)

    XCTAssertEqual(ctx["isAllDay"] as? Bool, true)
  }

  // MARK: - Nested: Calendar

  func testCalendarContextIsMapped() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: fullEvent)

    let cal = ctx["calendar"] as? [String: Any]
    XCTAssertNotNil(cal)
    XCTAssertEqual(cal?["title"] as? String, "Work")
    XCTAssertEqual(cal?["color"] as? String, "#1BADF8")
    XCTAssertEqual(cal?["type"] as? String, "calDAV")
    XCTAssertEqual(cal?["source"] as? String, "iCloud")
  }

  // MARK: - Nested: Organizer

  func testOrganizerContextIsMapped() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: fullEvent)

    let org = ctx["organizer"] as? [String: Any]
    XCTAssertNotNil(org)
    XCTAssertEqual(org?["name"] as? String, "Alice Smith")
    XCTAssertEqual(org?["email"] as? String, "alice@example.com")
  }

  func testOrganizerAbsentWhenNil() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: minimalEvent)

    XCTAssertNil(ctx["organizer"])
  }

  // MARK: - Nested: Recurrence

  func testRecurrenceContextIsMapped() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: fullEvent)

    let rec = ctx["recurrence"] as? [String: Any]
    XCTAssertNotNil(rec)
    XCTAssertEqual(rec?["isRecurring"] as? Bool, true)
    XCTAssertEqual(rec?["description"] as? String, "Every weekday")
  }

  func testRecurrenceContextWhenNotRecurring() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: minimalEvent)

    let rec = ctx["recurrence"] as? [String: Any]
    XCTAssertNotNil(rec)
    XCTAssertEqual(rec?["isRecurring"] as? Bool, false)
    XCTAssertEqual(rec?["description"] as? String, "")
  }

  // MARK: - Attendees

  func testAttendeesArrayIsMapped() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: fullEvent)

    let attendees = ctx["attendees"] as? [[String: Any]]
    XCTAssertNotNil(attendees)
    XCTAssertEqual(attendees?.count, 2)

    let alice = attendees?[0]
    XCTAssertEqual(alice?["name"] as? String, "Alice Smith")
    XCTAssertEqual(alice?["email"] as? String, "alice@example.com")
    XCTAssertEqual(alice?["status"] as? String, "accepted")
    XCTAssertEqual(alice?["role"] as? String, "required")
    XCTAssertEqual(alice?["isCurrentUser"] as? Bool, false)

    let bob = attendees?[1]
    XCTAssertEqual(bob?["name"] as? String, "Bob Jones")
    XCTAssertEqual(bob?["email"] as? String, "bob@example.com")
    XCTAssertEqual(bob?["status"] as? String, "tentative")
    XCTAssertEqual(bob?["role"] as? String, "optional")
    XCTAssertEqual(bob?["isCurrentUser"] as? Bool, true)
  }

  func testEmptyAttendeesArray() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: minimalEvent)

    let attendees = ctx["attendees"] as? [[String: Any]]
    XCTAssertNotNil(attendees)
    XCTAssertEqual(attendees?.count, 0)
  }

  // MARK: - Date/Time Formatting

  func testDefaultDateTimeFormats() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: fullEvent)

    // Verify time strings are formatted (exact values depend on timezone,
    // but they should be non-empty and not "All day")
    let startTime = ctx["startTime"] as? String
    let endTime = ctx["endTime"] as? String
    XCTAssertNotNil(startTime)
    XCTAssertNotNil(endTime)
    XCTAssertNotEqual(startTime, "All day")
    XCTAssertNotEqual(endTime, "All day")

    // Verify date strings are present
    let startDate = ctx["startDate"] as? String
    let endDate = ctx["endDate"] as? String
    XCTAssertNotNil(startDate)
    XCTAssertNotNil(endDate)
    XCTAssertFalse(startDate!.isEmpty)
    XCTAssertFalse(endDate!.isEmpty)
  }

  func testAllDayEventTimeStrings() {
    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: allDayEvent)

    XCTAssertEqual(ctx["startTime"] as? String, "All day")
    XCTAssertEqual(ctx["endTime"] as? String, "All day")

    // Date strings should still be formatted normally
    let startDate = ctx["startDate"] as? String
    XCTAssertNotNil(startDate)
    XCTAssertFalse(startDate!.isEmpty)
  }

  func testCustomDateTimeFormats() {
    let formats = TemplateDateFormats(
      timeFormat: "HH:mm",
      dateFormat: "yyyy-MM-dd"
    )
    let builder = EventTemplateContext(formats: formats)
    let ctx = builder.buildContext(for: fullEvent)

    // With 24-hour format, time should contain colons and no AM/PM
    let startTime = ctx["startTime"] as? String
    XCTAssertNotNil(startTime)
    XCTAssertTrue(startTime!.contains(":"))
    XCTAssertFalse(startTime!.contains("AM"))
    XCTAssertFalse(startTime!.contains("PM"))

    // With ISO-style date format, should contain dashes
    let startDate = ctx["startDate"] as? String
    XCTAssertNotNil(startDate)
    XCTAssertTrue(startDate!.contains("-"))
  }

  // MARK: - Empty Location String

  func testEmptyLocationStringTreatedAsMissing() {
    let event = CalendarEvent(
      id: "evt-empty",
      title: "Test",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: "",
      notes: "",
      url: nil,
      calendar: testCalendar,
      status: "none"
    )

    let builder = EventTemplateContext()
    let ctx = builder.buildContext(for: event)

    XCTAssertEqual(ctx["hasLocation"] as? Bool, false)
    XCTAssertEqual(ctx["hasNotes"] as? Bool, false)
  }
}

// MARK: - Mustache Rendering Integration

final class EventTemplateContextRenderingTests: XCTestCase {
  private let testCalendar = CalendarInfo(
    id: "cal-1", title: "Work", type: "calDAV", source: "iCloud", color: "#1BADF8"
  )

  private var fullEvent: CalendarEvent {
    CalendarEvent(
      id: "evt-123",
      title: "Team Standup",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false,
      location: "Conference Room B",
      notes: "Weekly sync meeting",
      url: "https://calendar.example.com/evt-123",
      meetingUrl: "https://zoom.us/j/123456",
      calendar: testCalendar,
      attendees: [
        Attendee(
          name: "Alice Smith", email: "alice@example.com",
          status: .accepted, role: .required, isCurrentUser: false
        ),
        Attendee(
          name: "Bob Jones", email: "bob@example.com",
          status: .tentative, role: .optional, isCurrentUser: true
        ),
      ],
      organizer: Organizer(name: "Alice Smith", email: "alice@example.com"),
      recurrence: RecurrenceInfo(isRecurring: true, description: "Every weekday"),
      status: "confirmed",
      availability: "busy",
      timeZone: "America/New_York"
    )
  }

  func testContextRendersWithMustacheTemplate() throws {
    let ctx = EventTemplateContext().buildContext(for: fullEvent)
    let template = try MustacheTemplate(string: "{{title}} [{{calendar.title}}]")
    XCTAssertEqual(template.render(ctx), "Team Standup [Work]")
  }

  func testBooleanSectionsInTemplate() throws {
    let ctx = EventTemplateContext().buildContext(for: fullEvent)
    let template = try MustacheTemplate(
      string: "{{#hasLocation}}Location: {{location}}{{/hasLocation}}"
    )
    XCTAssertEqual(template.render(ctx), "Location: Conference Room B")
  }

  func testInvertedSectionsInTemplate() throws {
    let event = CalendarEvent(
      id: "evt-456", title: "Quick Chat",
      startDate: Date(timeIntervalSince1970: 1_710_500_400),
      endDate: Date(timeIntervalSince1970: 1_710_502_200),
      isAllDay: false, location: nil, notes: nil, url: nil,
      calendar: testCalendar, status: "none"
    )
    let ctx = EventTemplateContext().buildContext(for: event)
    let template = try MustacheTemplate(
      string: "{{^hasLocation}}No location{{/hasLocation}}"
    )
    XCTAssertEqual(template.render(ctx), "No location")
  }

  func testAttendeeSectionInTemplate() throws {
    let ctx = EventTemplateContext().buildContext(for: fullEvent)
    let template = try MustacheTemplate(
      string: "{{#attendees}}{{name}} ({{status}}){{^last()}}, {{/last()}}{{/attendees}}"
    )
    let result = template.render(ctx)
    XCTAssertTrue(result.contains("Alice Smith (accepted)"))
    XCTAssertTrue(result.contains("Bob Jones (tentative)"))
  }

  func testOrganizerSectionInTemplate() throws {
    let ctx = EventTemplateContext().buildContext(for: fullEvent)
    let template = try MustacheTemplate(
      string: "{{#hasOrganizer}}Organized by {{organizer.name}}{{/hasOrganizer}}"
    )
    XCTAssertEqual(template.render(ctx), "Organized by Alice Smith")
  }

  func testRecurrenceSectionInTemplate() throws {
    let ctx = EventTemplateContext().buildContext(for: fullEvent)
    let template = try MustacheTemplate(
      string: "{{#isRecurring}}Recurs: {{recurrence.description}}{{/isRecurring}}"
    )
    XCTAssertEqual(template.render(ctx), "Recurs: Every weekday")
  }

  func testAllDayTemplateRendering() throws {
    let event = CalendarEvent(
      id: "evt-789", title: "Company Holiday",
      startDate: Date(timeIntervalSince1970: 1_710_460_800),
      endDate: Date(timeIntervalSince1970: 1_710_547_200),
      isAllDay: true, location: nil, notes: nil, url: nil,
      calendar: testCalendar, status: "confirmed"
    )
    let ctx = EventTemplateContext().buildContext(for: event)
    let template = try MustacheTemplate(string: "{{startTime}} - {{title}}")
    XCTAssertEqual(template.render(ctx), "All day - Company Holiday")
  }
}
