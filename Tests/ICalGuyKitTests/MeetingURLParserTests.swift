import XCTest

@testable import ICalGuyKit

final class MeetingURLParserTests: XCTestCase {
  private let parser = MeetingURLParser()

  // MARK: - Google Meet

  func testGoogleMeetURL() {
    let result = parser.extractMeetingURL(
      url: nil, location: nil, notes: "https://meet.google.com/abc-defg-hij")
    XCTAssertEqual(result, "https://meet.google.com/abc-defg-hij")
  }

  func testGoogleMeetEmbeddedInNotes() {
    let notes = """
      Join the meeting:\nhttps://meet.google.com/abc-defg-hij\n\nDial-in: +1 234-567-8901
      """
    let result = parser.extractMeetingURL(url: nil, location: nil, notes: notes)
    XCTAssertEqual(result, "https://meet.google.com/abc-defg-hij")
  }

  // MARK: - Zoom

  func testZoomURL() {
    let result = parser.extractMeetingURL(
      url: nil, location: nil, notes: "https://us02web.zoom.us/j/1234567890")
    XCTAssertEqual(result, "https://us02web.zoom.us/j/1234567890")
  }

  func testZoomURLWithQueryParams() {
    let url = "https://us02web.zoom.us/j/1234567890?pwd=abc123"
    let result = parser.extractMeetingURL(url: nil, location: nil, notes: url)
    XCTAssertEqual(result, url)
  }

  func testZoomPlainDomain() {
    let result = parser.extractMeetingURL(
      url: nil, location: nil, notes: "https://zoom.us/j/9876543210")
    XCTAssertEqual(result, "https://zoom.us/j/9876543210")
  }

  // MARK: - Microsoft Teams

  func testTeamsURL() {
    let url = "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc123"
    let result = parser.extractMeetingURL(url: nil, location: nil, notes: url)
    XCTAssertEqual(result, url)
  }

  // MARK: - WebEx

  func testWebExURL() {
    let url = "https://company.webex.com/company/join/meeting123"
    let result = parser.extractMeetingURL(url: nil, location: nil, notes: url)
    XCTAssertEqual(result, url)
  }

  func testWebExMeetURL() {
    let result = parser.extractMeetingURL(
      url: nil, location: nil, notes: "https://company.webex.com/meet/jsmith")
    XCTAssertEqual(result, "https://company.webex.com/meet/jsmith")
  }

  // MARK: - Priority Ordering

  func testURLFieldTakesPriority() {
    let result = parser.extractMeetingURL(
      url: "https://meet.google.com/aaa-bbbb-ccc",
      location: "https://zoom.us/j/111",
      notes: "https://zoom.us/j/222"
    )
    XCTAssertEqual(result, "https://meet.google.com/aaa-bbbb-ccc")
  }

  func testLocationTakesPriorityOverNotes() {
    let result = parser.extractMeetingURL(
      url: nil,
      location: "https://us02web.zoom.us/j/111",
      notes: "https://meet.google.com/aaa-bbbb-ccc"
    )
    XCTAssertEqual(result, "https://us02web.zoom.us/j/111")
  }

  // MARK: - No Match

  func testNoMatchReturnsNil() {
    let result = parser.extractMeetingURL(
      url: nil, location: "Conference Room B", notes: "Bring your laptop")
    XCTAssertNil(result)
  }

  func testAllNilReturnsNil() {
    let result = parser.extractMeetingURL(url: nil, location: nil, notes: nil)
    XCTAssertNil(result)
  }

  func testNonMeetingURLReturnsNil() {
    let result = parser.extractMeetingURL(
      url: "https://example.com/page", location: nil, notes: nil)
    XCTAssertNil(result)
  }

  // MARK: - Vendor Identification

  func testMatchIdentifiesMeetVendor() {
    let match = parser.extractMeetingURLMatch(
      url: nil, location: nil, notes: "https://meet.google.com/abc-defg-hij")
    XCTAssertEqual(match?.vendor, .meet)
    XCTAssertEqual(match?.url, "https://meet.google.com/abc-defg-hij")
  }

  func testMatchIdentifiesZoomVendor() {
    let match = parser.extractMeetingURLMatch(
      url: nil, location: nil, notes: "https://us02web.zoom.us/j/1234567890")
    XCTAssertEqual(match?.vendor, .zoom)
    XCTAssertEqual(match?.url, "https://us02web.zoom.us/j/1234567890")
  }

  func testMatchIdentifiesTeamsVendor() {
    let url = "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc123"
    let match = parser.extractMeetingURLMatch(url: nil, location: nil, notes: url)
    XCTAssertEqual(match?.vendor, .teams)
    XCTAssertEqual(match?.url, url)
  }

  func testMatchIdentifiesWebexVendor() {
    let match = parser.extractMeetingURLMatch(
      url: nil, location: nil, notes: "https://company.webex.com/meet/jsmith")
    XCTAssertEqual(match?.vendor, .webex)
    XCTAssertEqual(match?.url, "https://company.webex.com/meet/jsmith")
  }

  func testMatchReturnsNilForNoMatch() {
    let match = parser.extractMeetingURLMatch(
      url: nil, location: "Conference Room B", notes: "Bring your laptop")
    XCTAssertNil(match)
  }

  func testMatchPreservesFieldPriority() {
    let match = parser.extractMeetingURLMatch(
      url: "https://meet.google.com/aaa-bbbb-ccc",
      location: "https://us02web.zoom.us/j/111",
      notes: nil
    )
    XCTAssertEqual(match?.vendor, .meet)
    XCTAssertEqual(match?.url, "https://meet.google.com/aaa-bbbb-ccc")
  }
}
