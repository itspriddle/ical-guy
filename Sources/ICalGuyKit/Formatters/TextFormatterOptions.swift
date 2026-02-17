import Foundation

public struct TextFormatterOptions: Sendable {
  public let showCalendar: Bool
  public let showLocation: Bool
  public let showAttendees: Bool
  public let showMeetingUrl: Bool
  public let showNotes: Bool
  public let showUid: Bool

  public init(
    showCalendar: Bool = true,
    showLocation: Bool = true,
    showAttendees: Bool = true,
    showMeetingUrl: Bool = true,
    showNotes: Bool = false,
    showUid: Bool = false
  ) {
    self.showCalendar = showCalendar
    self.showLocation = showLocation
    self.showAttendees = showAttendees
    self.showMeetingUrl = showMeetingUrl
    self.showNotes = showNotes
    self.showUid = showUid
  }
}
