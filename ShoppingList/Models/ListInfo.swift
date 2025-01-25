import UIKit

struct ListInfo {
    let listId: UUID
    let title: String
    let date: Date
    private(set) var completed: Bool
    private(set) var pinned: Bool
    
    mutating func togglePinned() {
        self.pinned.toggle()
    }
    
    mutating func setCompleted(to state: Bool) {
        self.completed = state
    }
}
