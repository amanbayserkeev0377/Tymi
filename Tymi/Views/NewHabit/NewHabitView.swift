import SwiftUI
import SwiftData

struct NewHabitView: View {
    // MARK: - Environment & Presentation
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State Properties
    // Basic properties
    @State private var title = ""
    @State private var selectedType: HabitType = .count
    @State private var countGoal: Int = 1
    
    // Time picker state (for time habits)
    @State private var hours: Int = 1
    @State private var minutes: Int = 0
    
    // Active days
    @State private var activeDays: [Bool] = Array(repeating: true, count: 7)
    
    // Reminder
    @State private var isReminderEnabled = false
    @State private var reminderTime = Date()
    
    // Start date
    @State private var startDate = Date()
    
    // Focus states
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isCountFieldFocused: Bool
    
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
                    .focused($isNameFieldFocused)
                
                GoalSection(
                    selectedType: $selectedType,
                    countGoal: $countGoal,
                    hours: $hours,
                    minutes: $minutes
                )
                .focused($isCountFieldFocused)
                
                StartDateSection(startDate: $startDate)
                
                ReminderSection(
                    isReminderEnabled: $isReminderEnabled,
                    reminderTime: $reminderTime
                )
                
                Section(header: Text("Active days")) {
                    ActiveDaysSection(activeDays: $activeDays)
                }
                
                // "Add Habit" button in Form
                Section {
                    Button(action: {
                        saveHabit()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundStyle(
                                colorScheme == .dark ? .black : .white
                            )
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.primary : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!isFormValid)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Create habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.05)
                                )
                                .frame(width: 26, height: 26)
                            Image(systemName: "xmark")
                                .foregroundStyle(
                                    colorScheme == .dark ? Color.white.opacity(0.5) : Color.gray.opacity(0.8)
                                )
                                .font(.caption2)
                                .fontWeight(.black)
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(action: {
                        isNameFieldFocused = false
                        isCountFieldFocused = false
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .tint(.primary)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
            print("Would schedule notification for \(title) at \(reminderTime)")
        }
        
        dismiss()
    }
}

#Preview {
    NewHabitView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
