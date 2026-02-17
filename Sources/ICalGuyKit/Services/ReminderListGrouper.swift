import Foundation

public struct ReminderListGrouper: Sendable {
  public init() {}

  public func groupRemindersByList(_ reminders: [Reminder]) -> [ReminderListGroup] {
    let grouped = Dictionary(grouping: reminders) { $0.list.id }

    return grouped.values
      .map { reminders in
        ReminderListGroup(list: reminders[0].list, reminders: reminders)
      }
      .sorted {
        $0.list.title.localizedCaseInsensitiveCompare($1.list.title) == .orderedAscending
      }
  }
}
