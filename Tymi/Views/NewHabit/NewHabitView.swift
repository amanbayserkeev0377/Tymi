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
        ZStack {
            // Background blur dim
            Color.black.opacity(0.05)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
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

                // Form content
                ScrollView {
                    VStack(spacing: 16) {
                        // Name
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

                        StartDateSection(startDate: $viewModel.startDate)
                        GoalSection(goal: $viewModel.goal, type: $viewModel.type, isCountFieldFocused: $isCountFieldFocused)
                        WeekdaySelector(selectedDays: $viewModel.activeDays)
                        ReminderSection(isEnabled: $viewModel.reminderEnabled, time: $viewModel.reminderTime)
                            .frame(minHeight: 56)
                    }
                    .padding(.horizontal, 24)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
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
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
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
}
