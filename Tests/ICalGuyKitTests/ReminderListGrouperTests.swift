import Foundation
import XCTest

@testable import ICalGuyKit

final class ReminderListGrouperTests: XCTestCase {
  private var grouper: ReminderListGrouper!

  override func setUp() {
    super.setUp()
    grouper = ReminderListGrouper()
  }

  // MARK: - Helpers

  private func makeReminder(
    id: String = "rem-1",
    title: String = "Task",
    listId: String = "list-1",
    listTitle: String = "Personal"
  ) -> Reminder {
    Reminder(
      id: id,
      title: title,
      list: ReminderListInfo(
        id: listId,
        title: listTitle,
        color: "#FF0000",
        source: "iCloud"
      )
    )
  }

  // MARK: - Reminder List Grouping

  func testGroupRemindersByList() {
    let reminders = [
      makeReminder(id: "1", title: "Buy milk", listId: "list-1", listTitle: "Shopping"),
      makeReminder(id: "2", title: "Call dentist", listId: "list-2", listTitle: "Personal"),
      makeReminder(id: "3", title: "Buy eggs", listId: "list-1", listTitle: "Shopping"),
    ]

    let groups = grouper.groupRemindersByList(reminders)

    XCTAssertEqual(groups.count, 2)
    // Sorted by title: Personal < Shopping
    XCTAssertEqual(groups[0].list.title, "Personal")
    XCTAssertEqual(groups[0].reminders.count, 1)
    XCTAssertEqual(groups[1].list.title, "Shopping")
    XCTAssertEqual(groups[1].reminders.count, 2)
  }

  func testGroupRemindersByListEmpty() {
    let groups = grouper.groupRemindersByList([])
    XCTAssertTrue(groups.isEmpty)
  }
}
