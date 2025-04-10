import Foundation

struct Reminder: Identifiable, Codable, Equatable {
    let id: UUID
    var time: Date
    var days: Set<Int> // 1 = Monday, 7 = Sunday
    var isEnabled: Bool
    
    init(
        id: UUID = UUID(),
        time: Date,
        days: Set<Int> = Set(1...7),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.time = time
        self.days = days
        self.isEnabled = isEnabled
    }
    
    static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        lhs.id == rhs.id
    }
} 