import Foundation

public enum DurationTier: String, Codable, Sendable {
  case deep
  case focus
  case short
  case brief
}

public struct FreeSlot: Codable, Equatable, Sendable {
  public let start: Date
  public let end: Date
  public let durationMinutes: Int
  public let tier: DurationTier

  public init(start: Date, end: Date, durationMinutes: Int, tier: DurationTier) {
    self.start = start
    self.end = end
    self.durationMinutes = durationMinutes
    self.tier = tier
  }
}

public struct DayFreeSlots: Codable, Equatable, Sendable {
  public let date: Date
  public let dateLabel: String
  public let slots: [FreeSlot]
  public let totalFreeMinutes: Int

  public init(date: Date, dateLabel: String, slots: [FreeSlot], totalFreeMinutes: Int) {
    self.date = date
    self.dateLabel = dateLabel
    self.slots = slots
    self.totalFreeMinutes = totalFreeMinutes
  }
}

public struct WorkingHours: Codable, Equatable, Sendable {
  public let startHour: Int
  public let startMinute: Int
  public let endHour: Int
  public let endMinute: Int

  public init(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
    self.startHour = startHour
    self.startMinute = startMinute
    self.endHour = endHour
    self.endMinute = endMinute
  }

  public static func parse(_ value: String) -> WorkingHours? {
    let parts = value.split(separator: ":")
    guard parts.count == 2,
      let hour = Int(parts[0]),
      let minute = Int(parts[1]),
      hour >= 0, hour <= 23,
      minute >= 0, minute <= 59
    else { return nil }
    return WorkingHours(startHour: hour, startMinute: minute, endHour: 0, endMinute: 0)
  }

  public static func from(start: String, end: String) -> WorkingHours? {
    let startParts = start.split(separator: ":")
    let endParts = end.split(separator: ":")
    guard startParts.count == 2, endParts.count == 2,
      let sh = Int(startParts[0]), let sm = Int(startParts[1]),
      let eh = Int(endParts[0]), let em = Int(endParts[1]),
      sh >= 0, sh <= 23, sm >= 0, sm <= 59,
      eh >= 0, eh <= 23, em >= 0, em <= 59
    else { return nil }
    return WorkingHours(startHour: sh, startMinute: sm, endHour: eh, endMinute: em)
  }

  public static let `default` = WorkingHours(
    startHour: 9, startMinute: 0, endHour: 17, endMinute: 0
  )
}

public struct FreeTimeResult: Codable, Equatable, Sendable {
  public let days: [DayFreeSlots]
  public let totalFreeMinutes: Int
  public let workingHours: WorkingHours
  public let minDurationMinutes: Int
  public let dateRange: DateRange

  public init(
    days: [DayFreeSlots],
    totalFreeMinutes: Int,
    workingHours: WorkingHours,
    minDurationMinutes: Int,
    dateRange: DateRange
  ) {
    self.days = days
    self.totalFreeMinutes = totalFreeMinutes
    self.workingHours = workingHours
    self.minDurationMinutes = minDurationMinutes
    self.dateRange = dateRange
  }
}
