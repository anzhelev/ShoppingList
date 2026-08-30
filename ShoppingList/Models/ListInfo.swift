import Foundation

struct ListInfo {

    // MARK: - Public Properties
    let listId: UUID
    let title: String
    let date: Date
    private(set) var completed: Bool
    private(set) var pinned: Bool
    private(set) var reminderDate: Date?

    // MARK: - Initializers
    init(
        listId: UUID,
        title: String,
        date: Date,
        completed: Bool,
        pinned: Bool,
        reminderDate: Date? = nil
    ) {
        self.listId = listId
        self.title = title
        self.date = date
        self.completed = completed
        self.pinned = pinned
        self.reminderDate = reminderDate
    }

    // MARK: - Public Methods
    mutating func setCompleted(to state: Bool) {
        self.completed = state
    }

    mutating func setReminderDate(to date: Date?) {
        reminderDate = date
    }

    mutating func togglePinned() {
        pinned.toggle()
    }
}
