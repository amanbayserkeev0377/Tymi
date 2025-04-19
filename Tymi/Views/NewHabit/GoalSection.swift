import SwiftUI

struct GoalSection: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    
    @State private var timeDate: Date = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var countText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: "trophy")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if selectedType == .count {
                    TextField("Set your daily goal", text: $countText)
                        .keyboardType(.numberPad)
                        .tint(.primary)
                        .focused($isFocused)
                        .frame(minWidth: 190)
                        .onChange(of: countText) { _, newValue in
                            if let number = Int(newValue) {
                                countGoal = number
                            } else {
                                countGoal = 0
                            }
                        }
                } else {
                    DatePicker("", selection: $timeDate, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.primary)
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
                        countText = ""
                        countGoal = 0
                    } else {
                        hours = 1
                        minutes = 0
                        updateTimeDateFromHoursAndMinutes()
                    }
                }
            }
            .frame(height: 37)
        }
        .onAppear {
            updateTimeDateFromHoursAndMinutes()
            if selectedType == .count {
                countText = ""
                countGoal = 0
            }
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
    @Previewable @State var selectedType: HabitType = .count
    @Previewable @State var countGoal: Int = 0
    @Previewable @State var hours: Int = 1
    @Previewable @State var minutes: Int = 0
    
    return Form {
        GoalSection(
            selectedType: $selectedType,
            countGoal: $countGoal,
            hours: $hours,
            minutes: $minutes
        )
    }
}
