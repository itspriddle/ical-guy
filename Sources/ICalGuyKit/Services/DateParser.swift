import Foundation

public enum DateParseError: Error, LocalizedError {
    case invalidFormat(String)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let input):
            return "Invalid date format: '\(input)'. Use ISO 8601 (2024-03-15), 'today', 'tomorrow', 'yesterday', or 'today+N'/'today-N'."
        }
    }
}

public struct DateParser: Sendable {
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(calendar: Calendar = .current, now: @escaping @Sendable () -> Date = { Date() }) {
        self.calendar = calendar
        self.now = now
    }

    public func parse(_ input: String) throws -> Date {
        let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()

        if trimmed == "now" {
            return now()
        }

        if trimmed == "today" {
            return startOfToday()
        }

        if trimmed == "tomorrow" {
            return calendar.date(byAdding: .day, value: 1, to: startOfToday())!
        }

        if trimmed == "yesterday" {
            return calendar.date(byAdding: .day, value: -1, to: startOfToday())!
        }

        // today+N or today-N
        if trimmed.hasPrefix("today+") || trimmed.hasPrefix("today-") {
            let sign = trimmed.contains("+") ? 1 : -1
            let separator: Character = sign == 1 ? "+" : "-"
            let parts = trimmed.split(separator: separator, maxSplits: 1)
            guard parts.count == 2, let days = Int(parts[1]) else {
                throw DateParseError.invalidFormat(input)
            }
            return calendar.date(byAdding: .day, value: sign * days, to: startOfToday())!
        }

        // ISO 8601 date only: 2024-03-15
        if let date = parseISO8601DateOnly(trimmed) {
            return date
        }

        // ISO 8601 with time: 2024-03-15T09:00:00
        if let date = parseISO8601DateTime(trimmed) {
            return date
        }

        throw DateParseError.invalidFormat(input)
    }

    public func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    public func endOfDay(_ date: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar.date(from: components)!
    }

    private func startOfToday() -> Date {
        calendar.startOfDay(for: now())
    }

    private func parseISO8601DateOnly(_ input: String) -> Date? {
        let parts = input.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              year >= 1970, year <= 9999,
              month >= 1, month <= 12,
              day >= 1, day <= 31 else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)
    }

    private func parseISO8601DateTime(_ input: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: input) {
            return date
        }
        // Try without timezone (local)
        formatter.formatOptions = [.withFullDate, .withFullTime]
        formatter.timeZone = calendar.timeZone
        return formatter.date(from: input)
    }
}
