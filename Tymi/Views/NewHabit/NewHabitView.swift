import SwiftUI

struct NewHabitView: View {
    @StateObject private var viewModel: NewHabitViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isCountFieldFocused: Bool
    @Binding var isPresented: Bool
    
    init(habitStore: HabitStore, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: NewHabitViewModel(habitStore: habitStore))
        _isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            NewHabitContentView(
                viewModel: viewModel,
                isPresented: $isPresented,
                isNameFieldFocused: $isNameFieldFocused,
                isCountFieldFocused: $isCountFieldFocused,
                colorScheme: colorScheme
            )
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

private struct BackgroundView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            Color.black.opacity(0.05)
                .ignoresSafeArea()
        }
    }
}

private struct NewHabitContentView: View {
    @ObservedObject var viewModel: NewHabitViewModel
    @Binding var isPresented: Bool
    @FocusState.Binding var isNameFieldFocused: Bool
    @FocusState.Binding var isCountFieldFocused: Bool
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(isPresented: $isPresented, colorScheme: colorScheme)
            
            ScrollView {
                VStack(spacing: 24) {
                    NameFieldView(
                        name: $viewModel.name,
                        isNameFieldFocused: $isNameFieldFocused
                    )
                    
                    StartDateSection(startDate: $viewModel.startDate)
                        .padding(.horizontal, 24)
                    
                    GoalSection(
                        goal: $viewModel.goal,
                        type: $viewModel.type,
                        isCountFieldFocused: $isCountFieldFocused
                    )
                    .padding(.horizontal, 24)
                    
                    WeekdaySelector(selectedDays: $viewModel.activeDays)
                        .padding(.horizontal, 24)
                    
                    ReminderSection(
                        isEnabled: $viewModel.reminderEnabled,
                        time: $viewModel.reminderTime
                    )
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.immediately)
            
            SaveButtonView(
                isValid: viewModel.isValid,
                action: {
                    viewModel.createHabit()
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }
            )
        }
        .frame(maxWidth: min(600, UIScreen.main.bounds.width - 32))
        .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
        .background(GlassSectionBackground())
    }
}

private struct HeaderView: View {
    @Binding var isPresented: Bool
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            Text("New Habit")
                .font(.title3.weight(.semibold))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

private struct NameFieldView: View {
    @Binding var name: String
    @FocusState.Binding var isNameFieldFocused: Bool
    
    var body: some View {
        TextField("Habit Name", text: $name)
            .font(.title2.weight(.semibold))
            .focused($isNameFieldFocused)
            .padding(.horizontal, 24)
    }
}

private struct SaveButtonView: View {
    let isValid: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Save")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isValid)
        .opacity(isValid ? 1 : 0.5)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}
