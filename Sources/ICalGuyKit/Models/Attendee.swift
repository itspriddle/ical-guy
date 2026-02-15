import Foundation

public enum AttendeeStatus: String, Codable, Sendable {
  case accepted
  case declined
  case tentative
  case pending
  case delegated
  case completed
  case inProcess
  case unknown
}

public enum AttendeeRole: String, Codable, Sendable {
  case required
  case optional
  case chair
  case nonParticipant
  case unknown
}

public struct Attendee: Codable, Equatable, Sendable {
  public let name: String?
  public let email: String?
  public let status: AttendeeStatus
  public let role: AttendeeRole
  public let isCurrentUser: Bool

  public init(
    name: String?,
    email: String?,
    status: AttendeeStatus,
    role: AttendeeRole,
    isCurrentUser: Bool
  ) {
    self.name = name
    self.email = email
    self.status = status
    self.role = role
    self.isCurrentUser = isCurrentUser
  }
}
