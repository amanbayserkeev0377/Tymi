import SwiftUI
import SwiftData

struct NewHabitView: View {
    // MARK: - Environment & Presentation
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
    
    // Basic properties
    @State private var title = ""
    @State private var selectedType: HabitType = .count
    @State private var countGoal: Int = 1
    
    // Time picker state (for time habits)
    @State private var hours: Int = 0
    @State private var minutes: Int = 15
    
    // Active days
    @State private var activeDays: [Bool] = Array(repeating: true, count: 7)
    
    // Reminder
    @State private var isReminderEnabled = false
    @State private var reminderTime = Date()
    
    // Start date
    @State private var startDate = Date()
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (selectedType == .count ? countGoal > 0 : hours > 0 || minutes > 0)
    }
    
    private var effectiveGoal: Int {
        switch selectedType {
        case .count:
            return countGoal
        case .time:
            return (hours * 3600) + (minutes * 60)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                NameFieldSection(title: $title)
                
                StartDateSection(startDate: $startDate)
                
                GoalSection(
                    selectedType: $selectedType,
                    countGoal: $countGoal,
                    hours: $hours,
                    minutes: $minutes
                )
                
                ReminderSection(
                    isReminderEnabled: $isReminderEnabled,
                    reminderTime: $reminderTime
                )
                
                ActiveDaysSection(activeDays: $activeDays)
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(.primary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveHabit()
                    }
                    .tint(.primary)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveHabit() {
        let newHabit = Habit(
            title: title,
            type: selectedType,
            goal: effectiveGoal,
            createdAt: Date(),
            isArchived: false,
            activeDays: activeDays,
            reminderTime: isReminderEnabled ? reminderTime : nil,
            startDate: startDate
        )
        
        modelContext.insert(newHabit)
        
        // Schedule notification if reminder is enabled
        if isReminderEnabled {
            // Note: Implement notification scheduling in a real app
            print("Would schedule notification for \(title) at \(reminderTime)")
        }
        
        dismiss()
    }
}

#Preview {
    NewHabitView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
