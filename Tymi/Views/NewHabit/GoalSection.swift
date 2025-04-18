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
                Image(systemName: "trophy")
                    .foregroundStyle(Color.primary)
                    .font(.headline)
                
                if selectedType == .count {
                    HStack {
                        Text("Daily goal")
                        Spacer()
                        TextField("count", value: $countGoal, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("times")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        Text("Daily goal")
                        Spacer()
                        DatePicker("", selection: $timeDate, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .onChange(of: timeDate) { _, newValue in
                                updateHoursAndMinutesFromTimeDate()
                            }
                    }
                }
                
                Spacer()
                
                // Type toggle buttons
                HStack(spacing: 2) {
                    Image(systemName: "numbers")
                        .padding(8)
                        .background(selectedType == .count ? Color.primary.opacity(0.1) : Color.clear)
                        .foregroundStyle(selectedType == .count ? .primary : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedType != .count {
                                selectedType = .count
                                countGoal = 1
                            }
                        }
                    
                    Image(systemName: "clock")
                        .padding(8)
                        .background(selectedType == .time ? Color.primary.opacity(0.1) : Color.clear)
                        .foregroundStyle(selectedType == .time ? .primary : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedType != .time {
                                selectedType = .time
                                hours = 1
                                minutes = 0
                                updateTimeDateFromHoursAndMinutes()
                            }
                        }
                }
                .font(.subheadline)
            }
        } header: {
            Text("Goal")
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
    @State var hours: Int = 0
    @State var minutes: Int = 15
    
    return Form {
        GoalSection(
            selectedType: $selectedType,
            countGoal: $countGoal,
            hours: $hours,
            minutes: $minutes
        )
    }
}
