import SwiftUI

struct NewHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: NewHabitViewModel
    @FocusState private var focusedField: Field?
    @Binding var isPresented: Bool
    
    let onSave: (Habit) -> Void
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    enum Field {
        case name
        case count
    }
    
    init(habitStore: HabitStore, isPresented: Binding<Bool>, onSave: @escaping (Habit) -> Void) {
        _viewModel = StateObject(wrappedValue: NewHabitViewModel(habitStore: habitStore))
        _isPresented = isPresented
        self.onSave = onSave
    }
    
    var body: some View {
        ModalView(isPresented: $isPresented, title: "New Habit") {
            ZStack(alignment: .bottom) {
                VStack(spacing: 16) {
                    // Name Field
                    NameFieldView(name: $viewModel.name)
                        .focused($focusedField, equals: .name)
                    
                    // Goal Section
                    GoalSection(
                        goal: $viewModel.goal,
                        type: $viewModel.type,
                        isCountFieldFocused: focusedField == .count,
                        onTap: { focusedField = .count }
                    )
                    .focused($focusedField, equals: .count)
                    
                    // Weekday Selection
                    WeekdaySelector(selectedDays: $viewModel.activeDays)
                    
                    // Reminder Section
                    ReminderSection(
                        isEnabled: $viewModel.isReminderEnabled,
                        time: $viewModel.reminderTime
                    )
                    
                    // Start Date Section
                    StartDateSection(startDate: $viewModel.startDate)
                    
                    Spacer(minLength: 32)
                    
                    // Create Button
                    Button {
                        feedbackGenerator.prepare()
                        if let habit = viewModel.createHabit() {
                            feedbackGenerator.impactOccurred()
                            onSave(habit)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }
                    } label: {
                        Text("Create Habit")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        colorScheme == .dark
                                        ? Color.white.opacity(0.4)
                                        : Color.black
                                    )
                            )
                    }
                    .disabled(!viewModel.isValid)
                }
                .padding(.horizontal, 16)
                
                // Keyboard Dismiss Button
                if focusedField != nil {
                    KeyboardDismissButton {
                        focusedField = nil
                    }
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
