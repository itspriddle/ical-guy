import Foundation

public struct CalendarInfo: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let type: String
    public let source: String
    public let color: String

    public init(id: String, title: String, type: String, source: String, color: String) {
        self.id = id
        self.title = title
        self.type = type
        self.source = source
        self.color = color
    }
}
