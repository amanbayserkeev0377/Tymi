import SwiftUI

struct NewHabitView: View {
    @StateObject private var viewModel: NewHabitViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isCountFieldFocused: Bool
    
    var onSave: ((Habit) -> Void)?
    
    init(habitStore: HabitStore, isPresented: Binding<Bool>, onSave: ((Habit) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: NewHabitViewModel(habitStore: habitStore))
        _isPresented = isPresented
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Name Field
            NameFieldView(
                name: $viewModel.name,
                isFocused: $isNameFieldFocused
            )
            .padding(.horizontal, 24)
            
            // Type Selection
            HStack {
                Button {
                    viewModel.type = .count
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.title2.weight(.medium))
                        Text("Count")
                            .font(.caption.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.type == .count ? Color.primary.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    viewModel.type = .time
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.title2.weight(.medium))
                        Text("Time")
                            .font(.caption.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.type == .time ? Color.primary.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 24)
            
            // Goal Section
            GoalSection(
                goal: $viewModel.goal,
                type: $viewModel.type,
                isCountFieldFocused: $isCountFieldFocused
            )
            .padding(.horizontal, 24)
            
            // Weekday Selection
            WeekdaySelector(selectedDays: $viewModel.activeDays)
                .padding(.horizontal, 24)
            
            Spacer()
            
            // Save Button
            Button {
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                feedbackGenerator.prepare()
                
                if let habit = viewModel.createHabit() {
                    feedbackGenerator.impactOccurred()
                    onSave?(habit)
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
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
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.top, 24)
        .modalStyle(isPresented: $isPresented)
    }
}

// MARK: - NameFieldView
struct NameFieldView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var name: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "pencil")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 28, height: 28)
                
                TextField("Habit Name", text: $name)
                    .font(.title3.weight(.semibold))
                    .focused(isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .glassCard()
    }
}
