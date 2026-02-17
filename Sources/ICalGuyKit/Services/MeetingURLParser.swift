import Foundation

public struct MeetingURLMatch: Sendable, Equatable {
  public let url: String
  public let vendor: MeetingVendor

  public init(url: String, vendor: MeetingVendor) {
    self.url = url
    self.vendor = vendor
  }
}

public struct MeetingURLParser: Sendable {
  private static let vendorPatterns: [(MeetingVendor, String)] = [
    // Google Meet
    (.meet, "https?://meet\\.google\\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}[^\\s]*"),
    // Zoom
    (.zoom, "https?://(?:[a-z0-9]+\\.)?zoom\\.us/j/[0-9]+[^\\s]*"),
    // Microsoft Teams
    (.teams, "https?://teams\\.microsoft\\.com/l/meetup-join/[^\\s]+"),
    // WebEx
    (.webex, "https?://[a-z0-9]+\\.webex\\.com/[^\\s]*(?:meet|join)[^\\s]*"),
  ]

  public init() {}

  public func extractMeetingURLMatch(
    url: String?, location: String?, notes: String?
  ) -> MeetingURLMatch? {
    // Check fields in priority order: url > location > notes
    if let url, let match = findMeetingURLMatch(in: url) {
      return match
    }
    if let location, let match = findMeetingURLMatch(in: location) {
      return match
    }
    if let notes, let match = findMeetingURLMatch(in: notes) {
      return match
    }
    return nil
  }

  public func extractMeetingURL(url: String?, location: String?, notes: String?) -> String? {
    extractMeetingURLMatch(url: url, location: location, notes: notes)?.url
  }

  private func findMeetingURLMatch(in text: String) -> MeetingURLMatch? {
    for (vendor, pattern) in Self.vendorPatterns {
      if let range = text.range(of: pattern, options: .regularExpression) {
        return MeetingURLMatch(url: String(text[range]), vendor: vendor)
      }
    }
    return nil
  }
}
