import SwiftUI

struct NewHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: NewHabitViewModel
    @FocusState private var focusedField: Field?
    
    let onSave: (Habit) -> Void
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    enum Field {
        case name
        case count
    }
    
    init(habitStore: HabitStore, onSave: @escaping (Habit) -> Void) {
        _viewModel = StateObject(wrappedValue: NewHabitViewModel(habitStore: habitStore))
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button {
                            feedbackGenerator.impactOccurred()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    
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
                                withAnimation(.spring()) {
                                    dismiss()
                                }
                            }
                        } label: {
                            Text("Create Habit")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(height: 56)
                                .frame(maxWidth: .infinity)
                                .background(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(!viewModel.isValid)
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            // Keyboard Dismiss Button
            if focusedField != nil {
                HStack {
                    Spacer()
                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.body.weight(.medium))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 4)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 10)),
                    removal: .opacity.combined(with: .offset(y: 10))
                ))
            }
        }
    }
}

#Preview {
    NewHabitView(habitStore: HabitStore(), onSave: { _ in })
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
