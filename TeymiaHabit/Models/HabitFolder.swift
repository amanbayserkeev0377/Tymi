import Foundation
import SwiftData

@Model
final class HabitFolder: Hashable {
    var uuid: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var displayOrder: Int = 0
    
    @Relationship(deleteRule: .nullify, inverse: \Habit.folders)
    var habits: [Habit]?
    
    // MARK: - Computed Properties
    
    var id: String {
        return uuid.uuidString
    }
    
    var habitsCount: Int {
        habits?.filter { !$0.isArchived }.count ?? 0
    }
    
    var archivedHabitsCount: Int {
        habits?.filter { $0.isArchived }.count ?? 0
    }
    
    var totalHabitsCount: Int {
        habits?.count ?? 0
    }
    
    // MARK: - Hashable Implementation
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    static func == (lhs: HabitFolder, rhs: HabitFolder) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    // MARK: - Initializers
    
    init(
        name: String = "",
        displayOrder: Int = 0
    ) {
        self.uuid = UUID()
        self.name = name
        self.displayOrder = displayOrder
        self.createdAt = Date()
    }
    
    // MARK: - Methods
    
    func update(name: String) {
        self.name = name
    }
}
