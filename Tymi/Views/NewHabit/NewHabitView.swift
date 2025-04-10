import SwiftUI

struct NewHabitView: View {
    @StateObject private var viewModel: NewHabitViewModel
    @Binding var isPresented: Bool
    let habit: Habit?
    let onSave: (Habit) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    init(habitStore: HabitStoreManager, habit: Habit? = nil, isPresented: Binding<Bool>, onSave: @escaping (Habit) -> Void) {
        self._viewModel = StateObject(wrappedValue: NewHabitViewModel(habitStore: habitStore, habit: habit))
        self._isPresented = isPresented
        self.habit = habit
        self.onSave = onSave
    }
    
    var body: some View {
        Form {
            Section {
                NameFieldView(name: $viewModel.name)
            }
            
            Section {
                GoalSection(goal: $viewModel.goal, type: $viewModel.type)
            }
            
            Section {
                RepeatSection(
                    selectedDays: $viewModel.selectedDays,
                    repeatType: $viewModel.repeatType
                )
            }
            
            Section {
                ReminderSection(reminders: $viewModel.reminders)
            }
            
            Section {
                StartDateSection(startDate: $viewModel.startDate)
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
    }
    
    private var repeatDescription: String {
        switch viewModel.repeatType {
        case .daily:
            return "Every day"
        case .weekly:
            let days = viewModel.selectedDays.sorted().map { dayNumberToString($0) }
            return days.isEmpty ? "Select days" : days.joined(separator: ", ")
        }
    }
    
    private func dayNumberToString(_ day: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.shortWeekdaySymbols[day == 1 ? 6 : day - 2]
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

// MARK: - DaySelector
struct DaySelector: View {
    @Binding var selectedDays: Set<Int>
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Active Days")
                .font(.headline)
                .padding(.bottom, 8)
            
            HStack(spacing: 12) {
                ForEach(1...7, id: \.self) { day in
                    DayButton(
                        day: day,
                        isSelected: selectedDays.contains(day),
                        action: { toggleDay(day) }
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

struct DayButton: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var dayName: String {
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return weekdays[day - 1]
    }
    
    var body: some View {
        Button(action: action) {
            Text(dayName)
                .font(.caption.weight(.medium))
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : .gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
