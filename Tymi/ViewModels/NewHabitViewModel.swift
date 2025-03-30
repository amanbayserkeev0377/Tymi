import Foundation
import SwiftUI

@MainActor
final class NewHabitViewModel: ObservableObject {
    @Published var name: String - ""
    @Published var type: HabitType = .count
    @Published var goal: String = "1"
    @Published var startDate: Date = Date()
    @Published var activeDays: Set<Int> = Set(1...7)
    @Published var reminderEnabled: Bool = false
    @Published var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date()
    
    // Validation
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    private let habitStore: HabitStore
    
    init(habitStore: HabitStore) {
        self.habitStore = habitStore
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(goal) != nil &&
        !activeDays.isEmpty
    }
    
    func createHabit() {
        guard isValid else {
            showError = true
            errorMessage = "Please fill in all required fields"
            return
        }
        
        let goalValue: Double
        if type == .time {
            // Convert into minutes
            goalValue = (Double(goal) ?? 1) * 60
        } else {
            goalValue = Double(goal) ?? 1
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
