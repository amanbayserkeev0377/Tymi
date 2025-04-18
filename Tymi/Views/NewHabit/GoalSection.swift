import SwiftUI

struct GoalSection: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    
    @State private var timeDate: Date = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        Section {
            HStack {
                if selectedType == .count {
                    TextField("Count", value: $countGoal, format: .number)
                        .keyboardType(.numberPad)
                } else {
                    DatePicker("", selection: $timeDate, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: timeDate) { _, newValue in
                            updateHoursAndMinutesFromTimeDate()
                        }
                }
                
                Picker("", selection: $selectedType) {
                    Text("Count").tag(HabitType.count)
                    Text("Time").tag(HabitType.time)
                }
                .pickerStyle(.menu)
                .tint(.secondary)
                .onChange(of: selectedType) { oldValue, newValue in
                    if newValue == .count {
                        countGoal = 1
                    } else {
                        hours = 1
                        minutes = 0
                        updateTimeDateFromHoursAndMinutes()
                    }
                }
            }
        } header: {
            Text("Daily Goal")
        }
        .onAppear {
            updateTimeDateFromHoursAndMinutes()
        }
    }
    
    // Helper functions to sync between timeDate and hours/minutes
    private func updateHoursAndMinutesFromTimeDate() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: timeDate)
        hours = components.hour ?? 0
        minutes = components.minute ?? 0
    }
    
    private func updateTimeDateFromHoursAndMinutes() {
        timeDate = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    @State var selectedType: HabitType = .count
    @State var countGoal: Int = 1
    @State var hours: Int = 1
    @State var minutes: Int = 0
    
    return Form {
        GoalSection(
            selectedType: $selectedType,
            countGoal: $countGoal,
            hours: $hours,
            minutes: $minutes
        )
    }
}
