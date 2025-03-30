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
                    
                    Text("Add Habit")
                        .font(.title3.bold())
                    
                    Spacer()
                    
                    Button("Save") {
                        viewModel.createHabit()
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
                    .fontWeight(.medium)
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
        .presentationDragIndicator(.visible)
        .presentationBackground(.thinMaterial)
        .presentationBackgroundInteraction(.enabled)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
