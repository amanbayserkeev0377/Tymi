import Foundation
import SwiftUI

@MainActor
final class NewHabitViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var name: String = ""
    @Published var type: HabitType = .count
    @Published var goal: Double = 1
    @Published var selectedDays: Set<Int> = Set(1...7) // По умолчанию каждый день
    @Published var reminders: [Reminder] = []
    @Published var startDate: Date = Date()
    @Published var repeatType: RepeatType = .daily
    
    // MARK: - Error Handling
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Private Properties
    private let habitStore: HabitStoreManager
    private let habit: Habit?
    
    // MARK: - Initialization
    init(habitStore: HabitStoreManager, habit: Habit? = nil) {
        self.habitStore = habitStore
        self.habit = habit
        
        if let habit = habit {
            self.name = habit.name
            self.type = habit.type
            self.goal = habit.goal
            self.selectedDays = habit.activeDays
            self.reminders = habit.reminders
            self.startDate = habit.startDate
            self.repeatType = habit.activeDays.count == 7 ? .daily : .weekly
        }
    }
    
    // MARK: - Public Properties
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && goal > 0 && !selectedDays.isEmpty
    }
    
    // MARK: - Public Methods
    func createHabit() -> Habit {
        let habit = Habit(
            id: self.habit?.id ?? UUID(),
            name: name,
            type: type,
            goal: goal,
            startDate: startDate,
            activeDays: selectedDays,
            reminders: reminders
        )
        return habit
    }
    
    func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    func deselectAllDays() {
        selectedDays.removeAll()
    }
    
    func selectAllDays() {
        selectedDays = Set(1...7)
    }
}
