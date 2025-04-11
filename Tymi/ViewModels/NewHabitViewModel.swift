import Foundation
import SwiftUI

@MainActor
final class NewHabitViewModel: ObservableObject {
    // MARK: - Constants
    private let maxCountGoal: Int32 = Int32.max
    private let maxTimeGoal: Double = 999 * 3600 + 59 * 60
    
    // MARK: - Published Properties
    @Published var name: String = ""
    @Published var type: HabitType = .count
    @Published var goal: Double = 1
    @Published var selectedDays: Set<Int> = Set(1...7)
    @Published var reminder: Reminder = Reminder()
    @Published var startDate: Date = Date()
    @Published var repeatType: RepeatType = .daily
    @Published var showLimitAlert: Bool = false
    
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
            self.goal = habit.goal.doubleValue
            self.selectedDays = habit.activeDays
            self.reminder = habit.reminders.first(where: { $0.isEnabled }) ?? Reminder()
            self.startDate = habit.startDate
            self.repeatType = habit.activeDays.count == 7 ? .daily : .weekly
        }
    }
    
    // MARK: - Public Properties
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let validatedGoal = validateGoal(goal, type: type)
        return !trimmedName.isEmpty && validatedGoal > 0 && !selectedDays.isEmpty
    }
    
    // MARK: - Public Methods
    func createHabit() -> Habit {
        let validatedGoal = validateGoal(goal, type: type)
        if validatedGoal != goal {
            showLimitAlert = true
        }
        
        let goalValue: GoalValue = type == .count ? 
            .count(Int32(validatedGoal)) : 
            .time(validatedGoal)
        
        let habit = Habit(
            id: self.habit?.id ?? UUID(),
            name: name,
            type: type,
            goal: goalValue,
            startDate: startDate,
            activeDays: selectedDays,
            reminders: reminder.isEnabled ? [reminder] : [],
            isArchived: false
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
    
    // MARK: - Private Methods
    private func validateGoal(_ goal: Double, type: HabitType) -> Double {
        switch type {
        case .count:
            return min(goal, Double(maxCountGoal))
        case .time:
            return min(goal, maxTimeGoal)
        }
    }
}
