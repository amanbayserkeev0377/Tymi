import Foundation
import SwiftUI

@MainActor
final class NewHabitViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var name: String = ""
    @Published var type: HabitType = .count
    @Published var goal: Double = 1
    @Published var startDate: Date = Date()
    @Published var activeDays: Set<Int> = Set(1...7)
    @Published var isReminderEnabled: Bool = false
    @Published var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date()
    
    // MARK: - Error Handling
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Private Properties
    private let habitStore: HabitStoreManager
    
    // MARK: - Initialization
    init(habitStore: HabitStoreManager) {
        self.habitStore = habitStore
    }
    
    init(habitStore: HabitStoreManager, habit: Habit) {
        self.habitStore = habitStore
        self.name = habit.name
        self.type = habit.type
        self.goal = habit.goal
        self.startDate = habit.startDate
        self.activeDays = habit.activeDays
        self.isReminderEnabled = habit.reminderTime != nil
        if let reminderTime = habit.reminderTime {
            self.reminderTime = reminderTime
        }
    }
    
    // MARK: - Public Properties
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && goal > 0 && !activeDays.isEmpty
    }
    
    // MARK: - Public Methods
    func createHabit(id: UUID? = nil) -> Habit? {
        guard isValid else {
            showError = true
            errorMessage = "Please fill in all required fields"
            return nil
        }
        
        let habit = Habit(
            id: id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            goal: goal,
            startDate: startDate,
            activeDays: activeDays,
            reminderTime: isReminderEnabled ? reminderTime : nil
        )
        
        return habit
    }
    
    func toggleDay(_ day: Int) {
        if activeDays.contains(day) {
            activeDays.remove(day)
        } else {
            activeDays.insert(day)
        }
    }
    
    func deselectAllDays() {
        activeDays.removeAll()
    }
    
    func selectAllDays() {
        activeDays = Set(1...7)
    }
}
