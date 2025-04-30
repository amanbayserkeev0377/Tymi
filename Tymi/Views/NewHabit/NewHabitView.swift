import SwiftUI
import SwiftData

struct NewHabitView: View {
    // MARK: - Environment & Presentation
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Properties
    private let habit: Habit?
    
    // MARK: - State Properties
    @State private var title = ""
    @State private var selectedType: HabitType = .count
    @State private var countGoal: Int = 1
    @State private var hours: Int = 1
    @State private var minutes: Int = 0
    @State private var activeDays: [Bool] = Array(repeating: true, count: 7)
    @State private var isReminderEnabled = false
    @State private var reminderTime = Date()
    @State private var startDate = Date()
    
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isCountFieldFocused: Bool
    
    // MARK: - Initialization
    init(habit: Habit? = nil) {
        self.habit = habit
        if let habit = habit {
            _title = State(initialValue: habit.title)
            _selectedType = State(initialValue: habit.type)
            _countGoal = State(initialValue: habit.type == .count ? habit.goal : 1)
            _hours = State(initialValue: habit.type == .time ? habit.goal / 3600 : 1)
            _minutes = State(initialValue: habit.type == .time ? (habit.goal % 3600) / 60 : 0)
            _activeDays = State(initialValue: habit.activeDays)
            _isReminderEnabled = State(initialValue: habit.reminderTime != nil)
            _reminderTime = State(initialValue: habit.reminderTime ?? Date())
            _startDate = State(initialValue: habit.startDate)
        }
    }
    
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
                ScrollView {
                    VStack(spacing: 16) {
                        // Name
                        VStack {
                            NameFieldSectionContent(title: $title, isFocused: $isNameFieldFocused)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                        }
                        .background(sectionBackground)
                        .padding(.horizontal)
                        
                        // Goal
                        VStack {
                            GoalSectionContent(
                                selectedType: $selectedType,
                                countGoal: $countGoal,
                                hours: $hours,
                                minutes: $minutes
                            )
                            .focused($isCountFieldFocused)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .background(sectionBackground)
                        .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            // StartDate
                            StartDateSectionContent(startDate: $startDate)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            
                            Divider()
                                .padding(.leading, 48)
                            
                            // Reminder
                            ReminderSectionContent(
                                isReminderEnabled: $isReminderEnabled,
                                reminderTime: $reminderTime
                            )
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .background(sectionBackground)
                        .padding(.horizontal)
                        
                        // ActiveDays
                        VStack {
                            ActiveDaysSectionContent(activeDays: $activeDays)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                        }
                        .background(sectionBackground)
                        .padding(.horizontal)
                        
                        // Save Button
                        Button(action: {
                            saveHabit()
                        }) {
                            Text("Save")
                                .font(.headline)
                                .foregroundStyle(
                                    colorScheme == .dark ? .black : .white
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isFormValid ? Color.primary : Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!isFormValid)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 16)
                }
                .navigationTitle(title.isEmpty ? "Create habit" : "Edit habit")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            dismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
                                    )
                                    .frame(width: 26, height: 26)
                                Image(systemName: "xmark")
                                    .foregroundStyle(
                                        colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4)
                                    )
                                    .font(.caption2)
                                    .fontWeight(.black)
                            }
                            .padding(.trailing, 8)
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
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                        }
                )
            }
        }
        
        
        private var sectionBackground: some View {
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorScheme == .dark
                                ? Color.white.opacity(0.1)
                                : Color.black.opacity(0.1),
                                lineWidth: 0.5)
                )
                .shadow(radius: 0.5)
        }
        
        private func hideKeyboard() {
            isNameFieldFocused = false
            isCountFieldFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                          to: nil, from: nil, for: nil)
        }
        
        // MARK: - Actions
        private func saveHabit() {
            if let existingHabit = habit {
                // Update existing habit
                existingHabit.update(
                    title: title,
                    type: selectedType,
                    goal: effectiveGoal,
                    activeDays: activeDays,
                    reminderTime: isReminderEnabled ? reminderTime : nil,
                    startDate: startDate
                )
                
                if isReminderEnabled {
                    Task {
                        do {
                            try await NotificationManager.shared.requestAuthorization()
                            NotificationManager.shared.scheduleNotifications(for: existingHabit)
                        } catch {
                            print("Ошибка при обновлении уведомлений: \(error)")
                        }
                    }
                } else {
                    NotificationManager.shared.cancelNotifications(for: existingHabit)
                }
            } else {
                // Create new habit
                let newHabit = Habit(
                    title: title,
                    type: selectedType,
                    goal: effectiveGoal,
                    createdAt: Date(),
                    isFreezed: false,
                    activeDays: activeDays,
                    reminderTime: isReminderEnabled ? reminderTime : nil,
                    startDate: startDate
                )
                modelContext.insert(newHabit)
                
                if isReminderEnabled {
                    Task {
                        do {
                            try await NotificationManager.shared.requestAuthorization()
                            NotificationManager.shared.scheduleNotifications(for: newHabit)
                        } catch {
                            print("Ошибка при создании уведомлений: \(error)")
                        }
                    }
                }
            }
            
            dismiss()
        }
    }

#Preview {
    NewHabitView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
