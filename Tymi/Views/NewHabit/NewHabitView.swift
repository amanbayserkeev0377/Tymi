import SwiftUI
import SwiftData

struct NewHabitView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    // MARK: - Properties
    private let habit: Habit?
    
    // MARK: - State
    @State private var title = ""
    @State private var selectedType: HabitType = .count
    @State private var countGoal: Int = 1
    @State private var hours: Int = 1
    @State private var minutes: Int = 0
    @State private var activeDays: [Bool] = Array(repeating: true, count: 7)
    @State private var isReminderEnabled = false
    @State private var reminderTimes: [Date] = [Date()]
    @State private var startDate = Date()
    @State private var selectedIcon: String? = nil
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isCountFocused: Bool
    
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
            _isReminderEnabled = State(initialValue: habit.reminderTimes != nil && !habit.reminderTimes!.isEmpty)
            _reminderTimes = State(initialValue: habit.reminderTimes ?? [Date()])
            _startDate = State(initialValue: habit.startDate)
            _selectedIcon = State(initialValue: habit.iconName)
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
            let totalSeconds = (hours * 3600) + (minutes * 60)
            // Ограничиваем максимум 24 часами
            return min(totalSeconds, 86400)
        }
    }
    
    private var isKeyboardActive: Bool {
           isTitleFocused || isCountFocused
       }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    //Name
                    NameFieldSection(
                        title: $title,
                        isFocused: $isTitleFocused
                    )
                    
                    // Icon
                    IconSection(selectedIcon: $selectedIcon)
                }
                
                // Goal
                GoalSection(
                    selectedType: $selectedType,
                    countGoal: $countGoal,
                    hours: $hours,
                    minutes: $minutes,
                    isFocused: $isCountFocused
                )
                
                Section {
                    // Start Date
                    StartDateSection(startDate: $startDate)
                    
                    // Active Days
                    ActiveDaysSection(activeDays: $activeDays)
                }
                
                // Reminders
                Section {
                    ReminderSection(
                        isReminderEnabled: $isReminderEnabled,
                        reminderTimes: $reminderTimes
                    )
                }
            }
            .navigationTitle(habit == nil ? "create_habit".localized : "edit_habit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) {
                        saveHabit()
                    }
                    .disabled(!isFormValid)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isTitleFocused = false
                        isCountFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
            .animation(.default, value: isKeyboardActive)
        }
    }
    
    // MARK: - Methods
    private func saveHabit() {
        // Проверка и коррекция значений
        if selectedType == .count && countGoal > 999999 {
            countGoal = 999999
        }
        
        if selectedType == .time {
            let totalSeconds = (hours * 3600) + (minutes * 60)
            if totalSeconds > 86400 {
                hours = 24
                minutes = 0
            }
        }
        
        if let existingHabit = habit {
            // Обновление существующей привычки
            existingHabit.update(
                title: title,
                type: selectedType,
                goal: effectiveGoal,
                iconName: selectedIcon,
                activeDays: activeDays,
                reminderTimes: isReminderEnabled ? reminderTimes : nil,
                startDate: Calendar.current.startOfDay(for: startDate)
            )
            
            handleNotifications(for: existingHabit)
            habitsUpdateService.triggerUpdate()
        } else {
            // Создание новой привычки
            let newHabit = Habit(
                title: title,
                type: selectedType,
                goal: effectiveGoal,
                iconName: selectedIcon,
                createdAt: Date(),
                activeDays: activeDays,
                reminderTimes: isReminderEnabled ? reminderTimes : nil,
                startDate: startDate
            )
            modelContext.insert(newHabit)
            
            handleNotifications(for: newHabit)
            habitsUpdateService.triggerUpdate()
        }
        
        dismiss()
    }
    
    // Обработка уведомлений при сохранении
    private func handleNotifications(for habit: Habit) {
        if isReminderEnabled {
            Task {
                do {
                    let granted = try await NotificationManager.shared.requestAuthorization()
                    if granted {
                        let success = await NotificationManager.shared.scheduleNotifications(for: habit)
                        if !success {
                            print("Не удалось запланировать уведомления")
                        }
                    } else {
                        await MainActor.run {
                            // Если пользователь отказал в разрешениях
                            isReminderEnabled = false
                        }
                    }
                } catch {
                    print("Ошибка при обновлении уведомлений: \(error)")
                    await MainActor.run {
                        isReminderEnabled = false
                    }
                }
            }
        } else {
            // Отменяем существующие уведомления
            NotificationManager.shared.cancelNotifications(for: habit)
        }
    }
}
