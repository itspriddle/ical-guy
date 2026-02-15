import Foundation

public struct CalendarEvent: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String?
    public let notes: String?
    public let url: String?
    public let meetingUrl: String?
    public let calendar: CalendarInfo
    public let attendees: [String]
    public let isRecurring: Bool
    public let status: String

    public init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String?,
        notes: String?,
        url: String?,
        meetingUrl: String? = nil,
        calendar: CalendarInfo,
        attendees: [String],
        isRecurring: Bool,
        status: String
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.url = url
        self.meetingUrl = meetingUrl
        self.calendar = calendar
        self.attendees = attendees
        self.isRecurring = isRecurring
        self.status = status
    }
}
