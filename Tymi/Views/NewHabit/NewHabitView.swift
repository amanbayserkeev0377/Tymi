import SwiftUI
import SwiftData

struct NewHabitView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    // Query for folders
    @Query(sort: [SortDescriptor(\HabitFolder.displayOrder)])
    private var allFolders: [HabitFolder]
    
    // MARK: - Properties
    private let habit: Habit?
    private let initialFolder: HabitFolder?
    
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
    @State private var selectedIcon: String? = "checkmark"
    @State private var selectedIconColor: HabitIconColor = .primary
    @State private var selectedFolders: Set<HabitFolder> = []
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isCountFocused: Bool
    
    // MARK: - Initialization
    init(habit: Habit? = nil, initialFolder: HabitFolder? = nil) {
        self.habit = habit
        self.initialFolder = initialFolder
        
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
            _selectedIcon = State(initialValue: habit.iconName ?? "checkmark")
            _selectedIconColor = State(initialValue: habit.iconColor)
            _selectedFolders = State(initialValue: Set(habit.folders ?? []))
        } else if let initialFolder = initialFolder {
            _selectedFolders = State(initialValue: Set([initialFolder]))
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
                    // Name
                    NameFieldSection(
                        title: $title,
                        isFocused: $isTitleFocused
                    )
                    
                    // Icon
                    IconSection(selectedIcon: $selectedIcon, selectedColor: $selectedIconColor)
                }
                
                // Folder
                FolderSection(selectedFolders: $selectedFolders)
                
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
        // Validation and correction
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
                iconColor: selectedIconColor,
                activeDays: activeDays,
                reminderTime: isReminderEnabled ? reminderTimes.first : nil,
                startDate: Calendar.current.startOfDay(for: startDate)
            )
            
            // Update folders
            existingHabit.removeFromAllFolders()
            for folder in selectedFolders {
                existingHabit.addToFolder(folder)
            }
            
            handleNotifications(for: existingHabit)
            habitsUpdateService.triggerUpdate()
        } else {
            // Create new habit
            let newHabit = Habit(
                title: title,
                type: selectedType,
                goal: effectiveGoal,
                iconName: selectedIcon,
                iconColor: selectedIconColor,
                createdAt: Date(),
                activeDays: activeDays,
                reminderTimes: isReminderEnabled ? reminderTimes : nil,
                startDate: startDate
            )
            
            // Assign to folders
            for folder in selectedFolders {
                newHabit.addToFolder(folder)
            }
            
            modelContext.insert(newHabit)
            
            handleNotifications(for: newHabit)
            habitsUpdateService.triggerUpdate()
        }
        
        dismiss()
    }
    
    // Handle notifications when saving
    private func handleNotifications(for habit: Habit) {
        if isReminderEnabled {
            Task {
                // Check permissions using ensureAuthorization
                let isAuthorized = await NotificationManager.shared.ensureAuthorization()
                
                if isAuthorized {
                    let success = await NotificationManager.shared.scheduleNotifications(for: habit)
                    if !success {
                        print("Failed to schedule notifications")
                    }
                } else {
                    // If user denied permissions
                    isReminderEnabled = false
                }
            }
        } else {
            // Cancel existing notifications
            NotificationManager.shared.cancelNotifications(for: habit)
        }
    }
}
