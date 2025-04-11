import SwiftUI

struct NewHabitView: View {
    @StateObject private var viewModel: NewHabitViewModel
    @Binding var isPresented: Bool
    let habit: Habit?
    let onSave: (Habit) -> Void
    
    init(habitStore: HabitStoreManager, habit: Habit? = nil, isPresented: Binding<Bool>, onSave: @escaping (Habit) -> Void) {
        self._viewModel = StateObject(wrappedValue: NewHabitViewModel(habitStore: habitStore, habit: habit))
        self._isPresented = isPresented
        self.habit = habit
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NameFieldSection(name: $viewModel.name)
                }
                
                Section {
                    GoalSection(goal: $viewModel.goal, type: $viewModel.type)
                }
                
                Section {
                    RepeatSection(
                        selectedDays: $viewModel.selectedDays,
                        repeatType: $viewModel.repeatType
                    )
                    
                    StartDateSection(date: $viewModel.startDate)
                    
                    ReminderSection(reminder: $viewModel.reminder)
                }
            }
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let habit = viewModel.createHabit()
                        onSave(habit)
                        isPresented = false
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Goal Limit Reached", isPresented: $viewModel.showLimitAlert) {
                Button("OK") {
                    viewModel.showLimitAlert = false
                }
            } message: {
                Text("Maximum goal for Count is 2,147,483,647, for Timer is 999 hours 59 minutes.")
            }
        }
    }
}
