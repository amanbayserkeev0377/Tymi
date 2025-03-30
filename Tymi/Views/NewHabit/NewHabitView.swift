import SwiftUI

struct NewHabitView: View {
    @StateObject private var viewModel: NewHabitViewModel
    @FocusState private var isCountFieldFocused: Bool
    var isPresented: Binding<Bool>

    init(habitStore: HabitStore, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: NewHabitViewModel(habitStore: habitStore))
        self.isPresented = isPresented
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Habit")
                    .font(.title2.weight(.semibold))
                
                Spacer()
                
                Button("Save") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    viewModel.createHabit()
                    isPresented.wrappedValue = false
                }
                .font(.body.weight(viewModel.isValid ? .medium : .regular))
                .foregroundStyle(viewModel.isValid ? Color.primary : Color.secondary)
                .opacity(viewModel.isValid ? 1 : 0.5)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.isValid)
                .disabled(!viewModel.isValid)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Name field
                    HStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                        
                        TextField("Habit name", text: $viewModel.name)
                            .font(.title3)
                            .focused($isCountFieldFocused)
                    }
                    .frame(minHeight: 56)
                    .padding(.horizontal, 16)
                    .glassCard()
                    
                    // Start Date
                    StartDateSection(startDate: $viewModel.startDate)
                    
                    // Goal
                    GoalSection(goal: $viewModel.goal, type: $viewModel.type, isCountFieldFocused: $isCountFieldFocused)
                    
                    // Repeat
                    WeekdaySelector(selectedDays: $viewModel.activeDays)
                    
                    // Reminder
                    ReminderSection(
                        isEnabled: $viewModel.reminderEnabled,
                        time: $viewModel.reminderTime
                    )
                    .frame(minHeight: 56)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .foregroundStyle(.black)
                        .imageScale(.large)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

#Preview("NewHabitView Preview") {
    ZStack {
        TodayBackground()

        Color.black.opacity(0.1)
            .ignoresSafeArea()

        VStack {
            Spacer()
            NewHabitView(habitStore: HabitStore(), isPresented: .constant(false))
                .frame(height: UIScreen.main.bounds.height * 0.7)
                .padding(.horizontal)
        }
    }
    .preferredColorScheme(.light) // можно переключать на .dark для тёмной темы
}
