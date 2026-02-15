import Foundation

public struct MeetingURLParser: Sendable {
  private static let patterns: [String] = [
    // Google Meet
    "https?://meet\\.google\\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}[^\\s]*",
    // Zoom
    "https?://(?:[a-z0-9]+\\.)?zoom\\.us/j/[0-9]+[^\\s]*",
    // Microsoft Teams
    "https?://teams\\.microsoft\\.com/l/meetup-join/[^\\s]+",
    // WebEx
    "https?://[a-z0-9]+\\.webex\\.com/[^\\s]*(?:meet|join)[^\\s]*",
  ]

  private static let combinedPattern: String = patterns.map { "(\($0))" }.joined(separator: "|")

  public init() {}

  public func extractMeetingURL(url: String?, location: String?, notes: String?) -> String? {
    // Check fields in priority order: url > location > notes
    if let url, let match = findMeetingURL(in: url) {
      return match
    }
    if let location, let match = findMeetingURL(in: location) {
      return match
    }
    if let notes, let match = findMeetingURL(in: notes) {
      return match
    }
    return nil
  }

  private func findMeetingURL(in text: String) -> String? {
    guard
      let range = text.range(
        of: Self.combinedPattern,
        options: .regularExpression
      )
    else {
      return nil
    }
    return String(text[range])
  }
}
