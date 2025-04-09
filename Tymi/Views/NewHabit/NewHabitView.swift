import SwiftUI

struct NewHabitView: View {
    @StateObject private var viewModel: NewHabitViewModel
    @Binding var isPresented: Bool
    var onSave: (Habit) -> Void
    
    init(habitStore: HabitStoreManager, habit: Habit? = nil, isPresented: Binding<Bool>, onSave: @escaping (Habit) -> Void) {
        self._viewModel = StateObject(wrappedValue: habit == nil ? 
            NewHabitViewModel(habitStore: habitStore) : 
            NewHabitViewModel(habitStore: habitStore, habit: habit!))
        self._isPresented = isPresented
        self.onSave = onSave
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Habit Name", text: $viewModel.name)
            }
            
            Section {
                GoalSection(goal: $viewModel.goal)
            }
            
            Section {
                WeekdaySelector(selectedDays: $viewModel.activeDays)
            }
            
            Section {
                ReminderSection(
                    isEnabled: $viewModel.isReminderEnabled,
                    time: $viewModel.reminderTime
                )
            }
            
            Section {
                StartDateSection(startDate: $viewModel.startDate)
            }
        }
        .navigationTitle(viewModel.name.isEmpty ? "New Habit" : viewModel.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresented = false
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    if let habit = viewModel.createHabit() {
                        onSave(habit)
                        isPresented = false
                    }
                }
                .disabled(!viewModel.isValid)
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
    }
}
