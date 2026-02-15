import ArgumentParser
import Foundation
import ICalGuyKit

struct CalendarsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendars",
        abstract: "List available calendars as JSON."
    )

    func run() async throws {
        let store = LiveEventStore()
        try await store.requestAccess()

        let service = EventService(store: store)
        let calendars = try service.fetchCalendars()

        let data = try jsonEncode(calendars)
        print(String(data: data, encoding: .utf8)!)
    }
}
