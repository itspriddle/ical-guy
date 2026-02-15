import Foundation

public struct EventQuery: Sendable {
    public let startDate: Date
    public let endDate: Date
    public let calendars: [String]?

    public init(startDate: Date, endDate: Date, calendars: [String]? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.calendars = calendars
    }
}

public struct RawEvent: Sendable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String?
    public let notes: String?
    public let url: String?
    public let calendarId: String
    public let calendarTitle: String
    public let calendarType: String
    public let calendarSource: String
    public let calendarColor: String
    public let attendees: [String]
    public let isRecurring: Bool
    public let status: Int

    public init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String?,
        notes: String?,
        url: String?,
        calendarId: String,
        calendarTitle: String,
        calendarType: String,
        calendarSource: String,
        calendarColor: String,
        attendees: [String],
        isRecurring: Bool,
        status: Int
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.url = url
        self.calendarId = calendarId
        self.calendarTitle = calendarTitle
        self.calendarType = calendarType
        self.calendarSource = calendarSource
        self.calendarColor = calendarColor
        self.attendees = attendees
        self.isRecurring = isRecurring
        self.status = status
    }
}

public struct RawCalendar: Sendable {
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

public enum EventStoreError: Error, LocalizedError {
    case accessDenied
    case accessRestricted
    case queryFailed(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return """
                Calendar access denied. Grant access in:
                System Settings > Privacy & Security > Calendars
                """
        case .accessRestricted:
            return "Calendar access is restricted by a system policy."
        case .queryFailed(let message):
            return "Event query failed: \(message)"
        }
    }
}

public protocol EventStoreProtocol: Sendable {
    func requestAccess() async throws
    func calendars() throws -> [RawCalendar]
    func events(matching query: EventQuery) throws -> [RawEvent]
}
