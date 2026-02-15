import Foundation

public struct Organizer: Codable, Equatable, Sendable {
  public let name: String?
  public let email: String?

  public init(name: String?, email: String?) {
    self.name = name
    self.email = email
  }
}
