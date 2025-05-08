import SwiftUI
import SwiftData

struct NewHabitView: View {
    // MARK: - Environment & Presentation
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @EnvironmentObject private var habitsUpdateService: HabitsUpdateService
    
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
    @State private var selectedIcon: String? = nil
    @State private var isShowingIconPicker = false
    
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
    
    // Получаем адаптивные отступы в зависимости от размера экрана
    private var adaptiveHorizontalPadding: CGFloat {
        horizontalSizeClass == .compact ? 16 : 20
    }
    
    // Максимальная ширина содержимого для лучшей читаемости на больших экранах
    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .compact ? UIScreen.main.bounds.width - 32 : 600
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // Icon
                            IconSectionContent(selectedIcon: $selectedIcon)
                            
                            // Name
                            NameFieldSectionContent(title: $title, isFocused: $isNameFieldFocused)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(sectionBackground)
                    }
                    
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
                    
                    // ActiveDays
                    VStack {
                        ActiveDaysSectionContent(activeDays: $activeDays)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                    }
                    .background(sectionBackground)
                    
                    // Save Button
                    Button(action: {
                        saveHabit()
                    }) {
                        Text("save".localized)
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
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: contentMaxWidth)
            }
            .navigationTitle(habit == nil ? "create_habit".localized : "edit_habit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4)
                            )
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                            )
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
            .sheet(isPresented: $isShowingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
            }
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
    
    private func saveHabit() {
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
            // Update existing habit
            existingHabit.update(
                title: title,
                type: selectedType,
                goal: effectiveGoal,
                iconName: selectedIcon,
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
                iconName: selectedIcon,
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
