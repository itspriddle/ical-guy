import ArgumentParser
import Foundation
import ICalGuyKit

struct EventsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "events",
        abstract: "Query calendar events and output as JSON."
    )

    @Option(name: .long, help: "Start date (ISO 8601, 'today', 'tomorrow', 'yesterday', 'today+N').")
    var from: String?

    @Option(name: .long, help: "End date (same formats as --from).")
    var to: String?

    @Option(name: .long, help: "Only include these calendars (comma-separated titles).")
    var includeCalendars: String?

    @Option(name: .long, help: "Exclude these calendars (comma-separated titles).")
    var excludeCalendars: String?

    @Flag(name: .long, help: "Exclude all-day events.")
    var excludeAllDay = false

    @Option(name: .long, help: "Maximum number of events to output.")
    var limit: Int?

    func run() async throws {
        let store = LiveEventStore()
        try await store.requestAccess()

        let dateParser = DateParser()
        let fromDate: Date
        let toDate: Date

        if let fromInput = from {
            fromDate = try dateParser.parse(fromInput)
        } else {
            fromDate = dateParser.startOfDay(Date())
        }

        if let toInput = to {
            toDate = try dateParser.parse(toInput)
        } else {
            toDate = dateParser.endOfDay(fromDate)
        }

        let options = EventServiceOptions(
            from: fromDate,
            to: toDate,
            includeCalendars: includeCalendars?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            excludeCalendars: excludeCalendars?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            excludeAllDay: excludeAllDay,
            limit: limit
        )

        let service = EventService(store: store)
        let events = try service.fetchEvents(options: options)

        let data = try jsonEncode(events)
        print(String(data: data, encoding: .utf8)!)
    }
}
