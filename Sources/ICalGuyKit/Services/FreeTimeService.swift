import Foundation

public struct FreeTimeServiceOptions: Sendable {
  public let from: Date
  public let to: Date
  public let includeCalendars: [String]?
  public let excludeCalendars: [String]?
  public let includeAllDay: Bool
  public let minDuration: Int
  public let workingHours: WorkingHours

  public init(
    from: Date,
    to: Date,
    includeCalendars: [String]? = nil,
    excludeCalendars: [String]? = nil,
    includeAllDay: Bool = false,
    minDuration: Int = 30,
    workingHours: WorkingHours = .default
  ) {
    self.from = from
    self.to = to
    self.includeCalendars = includeCalendars
    self.excludeCalendars = excludeCalendars
    self.includeAllDay = includeAllDay
    self.minDuration = minDuration
    self.workingHours = workingHours
  }
}

public struct FreeTimeService: Sendable {
  private let eventService: EventService
  private let calendar: Calendar

  public init(store: any EventStoreProtocol, calendar: Calendar = .current) {
    self.eventService = EventService(store: store)
    self.calendar = calendar
  }

  public func findFreeTime(options: FreeTimeServiceOptions) throws -> FreeTimeResult {
    let events = try fetchAndFilter(options: options)
    let days = computeDays(events: events, options: options)
    let totalFree = days.reduce(0) { $0 + $1.totalFreeMinutes }

    return FreeTimeResult(
      days: days,
      totalFreeMinutes: totalFree,
      workingHours: options.workingHours,
      minDurationMinutes: options.minDuration,
      dateRange: DateRange(from: options.from, to: options.to)
    )
  }

  private func fetchAndFilter(
    options: FreeTimeServiceOptions
  ) throws -> [CalendarEvent] {
    let serviceOptions = EventServiceOptions(
      from: options.from,
      to: options.to,
      includeCalendars: options.includeCalendars,
      excludeCalendars: options.excludeCalendars,
      excludeAllDay: !options.includeAllDay
    )
    let events = try eventService.fetchEvents(options: serviceOptions)
    return filterForScheduling(events)
  }

  private func computeDays(
    events: [CalendarEvent], options: FreeTimeServiceOptions
  ) -> [DayFreeSlots] {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")

    var days: [DayFreeSlots] = []
    var currentDay = calendar.startOfDay(for: options.from)
    let endDay = calendar.startOfDay(for: options.to)

    while currentDay <= endDay {
      let windowStart = workingWindowStart(
        for: currentDay, options: options
      )
      let windowEnd = workingWindowEnd(for: currentDay, options: options)

      if windowStart >= windowEnd {
        let label = dateFormatter.string(from: currentDay)
        days.append(
          DayFreeSlots(
            date: currentDay, dateLabel: label, slots: [], totalFreeMinutes: 0
          )
        )
        currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
        continue
      }

      let dayEvents = events.filter { event in
        event.startDate < windowEnd && event.endDate > windowStart
      }

      let slots = findSlots(
        events: dayEvents,
        windowStart: windowStart,
        windowEnd: windowEnd,
        minDuration: options.minDuration
      )

      let totalFree = slots.reduce(0) { $0 + $1.durationMinutes }
      let label = dateFormatter.string(from: currentDay)

      days.append(
        DayFreeSlots(
          date: currentDay,
          dateLabel: label,
          slots: slots,
          totalFreeMinutes: totalFree
        )
      )

      currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
    }

    return days
  }

  private func workingWindowStart(
    for day: Date, options: FreeTimeServiceOptions
  ) -> Date {
    var components = calendar.dateComponents([.year, .month, .day], from: day)
    components.hour = options.workingHours.startHour
    components.minute = options.workingHours.startMinute
    components.second = 0
    let windowStart = calendar.date(from: components)!

    // If `from` is mid-day (e.g. --from now at 2pm), clip window start
    let isSameDay = calendar.isDate(options.from, inSameDayAs: day)
    if isSameDay && options.from > windowStart {
      return options.from
    }
    return windowStart
  }

  private func workingWindowEnd(
    for day: Date, options: FreeTimeServiceOptions
  ) -> Date {
    var components = calendar.dateComponents([.year, .month, .day], from: day)
    components.hour = options.workingHours.endHour
    components.minute = options.workingHours.endMinute
    components.second = 0
    return calendar.date(from: components)!
  }

  private func findSlots(
    events: [CalendarEvent],
    windowStart: Date,
    windowEnd: Date,
    minDuration: Int
  ) -> [FreeSlot] {
    // Clip events to window and merge overlapping intervals
    let busyBlocks = mergeBusyBlocks(
      events: events, windowStart: windowStart, windowEnd: windowEnd
    )

    // Find gaps between busy blocks
    var slots: [FreeSlot] = []
    var cursor = windowStart

    for block in busyBlocks {
      if cursor < block.start {
        let minutes = Int(block.start.timeIntervalSince(cursor)) / 60
        if minutes >= minDuration {
          slots.append(
            FreeSlot(
              start: cursor,
              end: block.start,
              durationMinutes: minutes,
              tier: tierFor(minutes: minutes)
            )
          )
        }
      }
      cursor = max(cursor, block.end)
    }

    // Gap after last busy block
    if cursor < windowEnd {
      let minutes = Int(windowEnd.timeIntervalSince(cursor)) / 60
      if minutes >= minDuration {
        slots.append(
          FreeSlot(
            start: cursor,
            end: windowEnd,
            durationMinutes: minutes,
            tier: tierFor(minutes: minutes)
          )
        )
      }
    }

    return slots
  }

  private struct BusyBlock {
    let start: Date
    let end: Date
  }

  private func mergeBusyBlocks(
    events: [CalendarEvent], windowStart: Date, windowEnd: Date
  ) -> [BusyBlock] {
    let clipped = events.compactMap { event -> BusyBlock? in
      let start = max(event.startDate, windowStart)
      let end = min(event.endDate, windowEnd)
      guard start < end else { return nil }
      return BusyBlock(start: start, end: end)
    }.sorted { $0.start < $1.start }

    guard !clipped.isEmpty else { return [] }

    var merged: [BusyBlock] = [clipped[0]]
    for block in clipped.dropFirst() {
      if block.start <= merged[merged.count - 1].end {
        let last = merged[merged.count - 1]
        merged[merged.count - 1] = BusyBlock(
          start: last.start, end: max(last.end, block.end)
        )
      } else {
        merged.append(block)
      }
    }

    return merged
  }
}

func tierFor(minutes: Int) -> DurationTier {
  if minutes >= 120 { return .deep }
  if minutes >= 60 { return .focus }
  if minutes >= 30 { return .short }
  return .brief
}
