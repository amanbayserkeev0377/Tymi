import SwiftUI

struct NewHabitView: View {
    @StateObject private var viewModel: NewHabitViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(habitStore: HabitStore) {
        _viewModel = StateObject(wrappedValue: NewHabitViewModel(habitStore: habitStore))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Spacer()
                    
                    Text("New Habit")
                        .font(.title3.bold())
                    
                    Spacer()
                    
                    Button("Save") {
                        viewModel.createHabit()
                        dismiss()
                    }
                    .font(.body.weight(viewModel.isValid ? .medium : .regular))
                    .foregroundStyle(viewModel.isValid ? Color.primary : Color.secondary)
                    .opacity(viewModel.isValid ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isValid)
                    .disabled(!viewModel.isValid)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Content
                VStack(spacing: 20) {
                    // Name field
                    HStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                        
                        TextField("Habit name", text: $viewModel.name)
                            .font(.title3)
                    }
                    .padding(16)
                    .glassCard()
                    
                    // Start Date
                    StartDateSection(startDate: $viewModel.startDate)
                    
                    // Goal
                    GoalSection(goal: $viewModel.goal, type: $viewModel.type)
                    
                    // Repeat
                    WeekdaySelector(selectedDays: $viewModel.activeDays)
                    
                    // Reminder
                    ReminderSection(
                        isEnabled: $viewModel.reminderEnabled,
                        time: $viewModel.reminderTime
                    )
                }
                .padding(.horizontal)
            }
        }
        .background(
            Rectangle()
                .fill(.thinMaterial.opacity(0.9))
                .ignoresSafeArea()
        )
        .presentationDetents([.fraction(0.7)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.thinMaterial)
        .presentationBackgroundInteraction(.enabled)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
