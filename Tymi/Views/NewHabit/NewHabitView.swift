import SwiftUI

struct NewHabitView: View {
    @StateObject private var viewModel: NewHabitViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let onSave: (Habit) -> Void
    @State private var isCountFieldFocused: Bool = false
    
    private var isEditMode: Bool {
        viewModel.name != ""
    }
    
    init(habitStore: HabitStoreManager, habit: Habit? = nil, isPresented: Binding<Bool>, onSave: @escaping (Habit) -> Void) {
        let vm = NewHabitViewModel(habitStore: habitStore)
        if let habit = habit {
            vm.name = habit.name
            vm.type = habit.type
            vm.goal = habit.goal
            vm.startDate = habit.startDate
            vm.activeDays = habit.activeDays
            vm.isReminderEnabled = habit.reminderTime != nil
            vm.reminderTime = habit.reminderTime ?? Date()
        }
        _viewModel = StateObject(wrappedValue: vm)
        _isPresented = isPresented
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Name Field
                    TextField("Habit name", text: $viewModel.name)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
                        )
                        .padding(.horizontal, 24)
                    
                    // Goal Section
                    GoalSection(
                        goal: $viewModel.goal,
                        type: $viewModel.type,
                        isCountFieldFocused: isCountFieldFocused,
                        onTap: { isCountFieldFocused = true }
                    )
                    .padding(.horizontal, 24)
                    
                    // Weekday Selector
                    WeekdaySelector(selectedDays: $viewModel.activeDays)
                        .padding(.horizontal, 24)
                    
                    // Reminder Section
                    ReminderSection(
                        isEnabled: $viewModel.isReminderEnabled,
                        time: $viewModel.reminderTime
                    )
                    .padding(.horizontal, 24)
                    
                    // Start Date Section
                    StartDateSection(startDate: $viewModel.startDate)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle(isEditMode ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Save" : "Create") {
                        if let habit = viewModel.createHabit() {
                            onSave(habit)
                            isPresented = false
                        }
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - NameFieldView
struct NameFieldView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "pencil")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 28, height: 28)
                
                TextField("Habit Name", text: $name)
                    .font(.title3.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .glassCard()
    }
}
