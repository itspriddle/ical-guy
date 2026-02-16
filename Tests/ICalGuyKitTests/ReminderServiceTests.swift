import Foundation
import XCTest

@testable import ICalGuyKit

final class ReminderServiceTests: XCTestCase {
  private var store: MockReminderStore!
  private var service: ReminderService!

  override func setUp() {
    super.setUp()
    store = MockReminderStore()
    service = ReminderService(store: store)
  }

  // MARK: - Fetch Incomplete

  func testFetchIncompleteReminders() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(id: "r1", title: "Task A", isCompleted: false),
      MockReminderStore.sampleReminder(id: "r2", title: "Task B", isCompleted: true),
      MockReminderStore.sampleReminder(id: "r3", title: "Task C", isCompleted: false),
    ]

    let options = ReminderServiceOptions(filter: .incomplete)
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders.count, 2)
    XCTAssertTrue(reminders.allSatisfy { !$0.isCompleted })
  }

  // MARK: - Fetch Completed

  func testFetchCompletedReminders() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(id: "r1", title: "Task A", isCompleted: false),
      MockReminderStore.sampleReminder(id: "r2", title: "Task B", isCompleted: true),
    ]

    let options = ReminderServiceOptions(filter: .completed)
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders.count, 1)
    XCTAssertEqual(reminders[0].title, "Task B")
    XCTAssertTrue(reminders[0].isCompleted)
  }

  // MARK: - Fetch All

  func testFetchAllReminders() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(id: "r1", title: "Task A", isCompleted: false),
      MockReminderStore.sampleReminder(id: "r2", title: "Task B", isCompleted: true),
    ]

    let options = ReminderServiceOptions(filter: .all)
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders.count, 2)
  }

  // MARK: - Filter by Include Lists

  func testFilterByIncludeLists() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(
        id: "r1", title: "Work task", calendarTitle: "Work"
      ),
      MockReminderStore.sampleReminder(
        id: "r2", title: "Personal task", calendarTitle: "Personal"
      ),
      MockReminderStore.sampleReminder(
        id: "r3", title: "Shopping", calendarTitle: "Shopping"
      ),
    ]

    let options = ReminderServiceOptions(
      filter: .incomplete, includeLists: ["Work", "Shopping"]
    )
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders.count, 2)
    let titles = Set(reminders.map { $0.title })
    XCTAssertTrue(titles.contains("Work task"))
    XCTAssertTrue(titles.contains("Shopping"))
  }

  // MARK: - Filter by Exclude Lists

  func testFilterByExcludeLists() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(
        id: "r1", title: "Work task", calendarTitle: "Work"
      ),
      MockReminderStore.sampleReminder(
        id: "r2", title: "Personal task", calendarTitle: "Personal"
      ),
    ]

    let options = ReminderServiceOptions(
      filter: .incomplete, excludeLists: ["Work"]
    )
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders.count, 1)
    XCTAssertEqual(reminders[0].title, "Personal task")
  }

  // MARK: - Case-Insensitive List Filtering

  func testFilterByListsCaseInsensitive() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(
        id: "r1", title: "Task A", calendarTitle: "Work"
      ),
      MockReminderStore.sampleReminder(
        id: "r2", title: "Task B", calendarTitle: "Personal"
      ),
    ]

    let options = ReminderServiceOptions(
      filter: .incomplete, includeLists: ["work"]
    )
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders.count, 1)
    XCTAssertEqual(reminders[0].title, "Task A")
  }

  // MARK: - Sort by Due Date

  func testSortByDueDate() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(
        id: "r1", title: "Later",
        dueDateComponents: RawDateComponents(year: 2026, month: 3, day: 15)
      ),
      MockReminderStore.sampleReminder(
        id: "r2", title: "Earlier",
        dueDateComponents: RawDateComponents(year: 2026, month: 2, day: 10)
      ),
      MockReminderStore.sampleReminder(
        id: "r3", title: "No date"
      ),
    ]

    let options = ReminderServiceOptions(filter: .incomplete, sortBy: .dueDate)
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders[0].title, "Earlier")
    XCTAssertEqual(reminders[1].title, "Later")
    XCTAssertEqual(reminders[2].title, "No date")
  }

  // MARK: - Sort by Priority

  func testSortByPriority() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(id: "r1", title: "Low", priority: 9),
      MockReminderStore.sampleReminder(id: "r2", title: "High", priority: 1),
      MockReminderStore.sampleReminder(id: "r3", title: "None", priority: 0),
      MockReminderStore.sampleReminder(id: "r4", title: "Medium", priority: 5),
    ]

    let options = ReminderServiceOptions(filter: .incomplete, sortBy: .priority)
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders[0].title, "High")
    XCTAssertEqual(reminders[1].title, "Medium")
    XCTAssertEqual(reminders[2].title, "Low")
    XCTAssertEqual(reminders[3].title, "None")
  }

  // MARK: - Sort by Title

  func testSortByTitle() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(id: "r1", title: "Charlie"),
      MockReminderStore.sampleReminder(id: "r2", title: "Alpha"),
      MockReminderStore.sampleReminder(id: "r3", title: "Bravo"),
    ]

    let options = ReminderServiceOptions(filter: .incomplete, sortBy: .title)
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders[0].title, "Alpha")
    XCTAssertEqual(reminders[1].title, "Bravo")
    XCTAssertEqual(reminders[2].title, "Charlie")
  }

  // MARK: - Limit

  func testLimitAppliedAfterSort() async throws {
    store.mockReminders = [
      MockReminderStore.sampleReminder(id: "r1", title: "C"),
      MockReminderStore.sampleReminder(id: "r2", title: "A"),
      MockReminderStore.sampleReminder(id: "r3", title: "B"),
    ]

    let options = ReminderServiceOptions(
      filter: .incomplete, limit: 2, sortBy: .title
    )
    let reminders = try await service.fetchReminders(options: options)

    XCTAssertEqual(reminders.count, 2)
    XCTAssertEqual(reminders[0].title, "A")
    XCTAssertEqual(reminders[1].title, "B")
  }

  // MARK: - DateComponents Resolution

  func testResolveDateComponentsDateOnly() {
    let components = RawDateComponents(year: 2026, month: 2, day: 20)
    let date = ReminderService.resolveDateComponents(components)
    XCTAssertNotNil(date)

    let cal = Calendar.current
    let dc = cal.dateComponents([.year, .month, .day], from: date!)
    XCTAssertEqual(dc.year, 2026)
    XCTAssertEqual(dc.month, 2)
    XCTAssertEqual(dc.day, 20)
  }

  func testResolveDateComponentsWithTime() {
    let components = RawDateComponents(
      year: 2026, month: 2, day: 20, hour: 14, minute: 30
    )
    let date = ReminderService.resolveDateComponents(components)
    XCTAssertNotNil(date)

    let cal = Calendar.current
    let dc = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date!)
    XCTAssertEqual(dc.year, 2026)
    XCTAssertEqual(dc.month, 2)
    XCTAssertEqual(dc.day, 20)
    XCTAssertEqual(dc.hour, 14)
    XCTAssertEqual(dc.minute, 30)
  }

  func testResolveDateComponentsNil() {
    let date = ReminderService.resolveDateComponents(nil)
    XCTAssertNil(date)
  }

  func testResolveDateComponentsIncomplete() {
    // Missing day — should return nil
    let components = RawDateComponents(year: 2026, month: 2)
    let date = ReminderService.resolveDateComponents(components)
    XCTAssertNil(date)
  }

  // MARK: - Priority Mapping

  func testPriorityMappingNone() {
    XCTAssertEqual(ReminderPriority(rawPriority: 0), .none)
  }

  func testPriorityMappingHigh() {
    for p in 1...4 {
      XCTAssertEqual(ReminderPriority(rawPriority: p), .high, "Priority \(p) should be high")
    }
  }

  func testPriorityMappingMedium() {
    XCTAssertEqual(ReminderPriority(rawPriority: 5), .medium)
  }

  func testPriorityMappingLow() {
    for p in 6...9 {
      XCTAssertEqual(ReminderPriority(rawPriority: p), .low, "Priority \(p) should be low")
    }
  }

  // MARK: - Fetch Reminder Lists

  func testFetchReminderLists() throws {
    store.mockReminderLists = [
      MockReminderStore.sampleReminderList(
        id: "list-1", title: "Personal", color: "#FF9500", source: "iCloud"
      ),
      MockReminderStore.sampleReminderList(
        id: "list-2", title: "Work", color: "#007AFF", source: "iCloud"
      ),
    ]

    let lists = try service.fetchReminderLists()

    XCTAssertEqual(lists.count, 2)
    XCTAssertEqual(lists[0].title, "Personal")
    XCTAssertEqual(lists[0].color, "#FF9500")
    XCTAssertEqual(lists[1].title, "Work")
  }

  // MARK: - Access Denied

  func testAccessDeniedThrows() async {
    store.accessGranted = false

    do {
      try await store.requestAccess()
      XCTFail("Expected access denied error")
    } catch {
      XCTAssertTrue(error is ReminderStoreError)
    }
  }
}
