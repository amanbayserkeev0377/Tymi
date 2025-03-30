import Foundation
import SwiftUI

@MainActor
final class NewHabitViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var name: String = ""
    @Published var type: HabitType = .count
    @Published var goal: String = "1"
    @Published var startDate: Date = Date()
    @Published var activeDays: Set<Int> = Set(1...7)
    @Published var reminderEnabled: Bool = false
    @Published var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date()
    
    // MARK: - Error Handling
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Private Properties
    private let habitStore: HabitStore
    
    // MARK: - Initialization
    init(habitStore: HabitStore) {
        self.habitStore = habitStore
    }
    
    // MARK: - Public Properties
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasValidGoal = Double(goal) != nil && Double(goal)! > 0
        return !trimmedName.isEmpty && hasValidGoal && !activeDays.isEmpty
    }
    
    // MARK: - Public Methods
    func createHabit() {
        guard isValid else {
            showError = true
            errorMessage = "Please fill in all required fields"
            return
        }
        
        let goalValue: Double
        if type == .time {
            goalValue = Double(goal)! * 60 // Convert minutes to seconds
        } else {
            goalValue = Double(goal)!
        }
        
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            goal: goalValue,
            startDate: startDate,
            activeDays: activeDays,
            reminderTime: reminderEnabled ? reminderTime : nil
        )
        
        habitStore.addHabit(habit)
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
