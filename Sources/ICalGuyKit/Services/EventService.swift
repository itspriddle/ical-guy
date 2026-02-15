import Foundation

public struct EventServiceOptions: Sendable {
    public let from: Date
    public let to: Date
    public let includeCalendars: [String]?
    public let excludeCalendars: [String]?
    public let excludeAllDay: Bool
    public let limit: Int?

    public init(
        from: Date,
        to: Date,
        includeCalendars: [String]? = nil,
        excludeCalendars: [String]? = nil,
        excludeAllDay: Bool = false,
        limit: Int? = nil
    ) {
        self.from = from
        self.to = to
        self.includeCalendars = includeCalendars
        self.excludeCalendars = excludeCalendars
        self.excludeAllDay = excludeAllDay
        self.limit = limit
    }
}

public struct EventService: Sendable {
    private let store: any EventStoreProtocol

    public init(store: any EventStoreProtocol) {
        self.store = store
    }

    public func fetchEvents(options: EventServiceOptions) throws -> [CalendarEvent] {
        let query = EventQuery(
            startDate: options.from,
            endDate: options.to
        )

        var rawEvents = try store.events(matching: query)

        // Filter by included calendars
        if let include = options.includeCalendars, !include.isEmpty {
            let includeSet = Set(include.map { $0.lowercased() })
            rawEvents = rawEvents.filter { includeSet.contains($0.calendarTitle.lowercased()) }
        }

        // Filter by excluded calendars
        if let exclude = options.excludeCalendars, !exclude.isEmpty {
            let excludeSet = Set(exclude.map { $0.lowercased() })
            rawEvents = rawEvents.filter { !excludeSet.contains($0.calendarTitle.lowercased()) }
        }

        // Filter all-day events
        if options.excludeAllDay {
            rawEvents = rawEvents.filter { !$0.isAllDay }
        }

        // Sort by start date, then title
        rawEvents.sort { a, b in
            if a.startDate == b.startDate {
                return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            }
            return a.startDate < b.startDate
        }

        // Apply limit
        if let limit = options.limit, limit > 0 {
            rawEvents = Array(rawEvents.prefix(limit))
        }

        return rawEvents.map { raw in
            CalendarEvent(
                id: raw.id,
                title: raw.title,
                startDate: raw.startDate,
                endDate: raw.endDate,
                isAllDay: raw.isAllDay,
                location: raw.location,
                notes: raw.notes,
                url: raw.url,
                calendar: CalendarInfo(
                    id: raw.calendarId,
                    title: raw.calendarTitle,
                    type: raw.calendarType,
                    source: raw.calendarSource,
                    color: raw.calendarColor
                ),
                attendees: raw.attendees,
                isRecurring: raw.isRecurring,
                status: statusString(from: raw.status)
            )
        }
    }

    public func fetchCalendars() throws -> [CalendarInfo] {
        try store.calendars().map { raw in
            CalendarInfo(
                id: raw.id,
                title: raw.title,
                type: raw.type,
                source: raw.source,
                color: raw.color
            )
        }
    }

    private func statusString(from status: Int) -> String {
        switch status {
        case 0: return "none"
        case 1: return "confirmed"
        case 2: return "tentative"
        case 3: return "canceled"
        default: return "none"
        }
    }
}
