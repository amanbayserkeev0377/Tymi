import SwiftUI

struct GoalSectionContent: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    
    @State private var timeDate: Date = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var countText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "trophy")
                        .foregroundStyle(.primary)
                        .frame(width: 24, height: 24)
                    
                    Text("daily_goal".localized)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Picker("", selection: $selectedType.animation()) {
                        Text("count".localized)
                            .tag(HabitType.count)
                        
                        Text("time".localized,)
                            .tag(HabitType.time)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 170)
                }
                .frame(height: 37)
                
                Divider()
                .padding(.leading, 24)
                
                HStack {
                    if selectedType == .count {
                        TextField("set_daily_goal".localized, text: $countText)
                            .keyboardType(.numberPad)
                            .tint(.primary)
                            .focused($isFocused)
                            .onChange(of: countText) { _, newValue in
                                if let number = Int(newValue) {
                                    countGoal = min(number, 999999)
                                } else {
                                    countGoal = 0
                                }
                            }
                            .transition(.opacity)
                    } else {
                        Spacer()
                        DatePicker("", selection: $timeDate, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.primary)
                            .onChange(of: timeDate) { _, newValue in
                                updateHoursAndMinutesFromTimeDate()
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .frame(height: 37)
                .padding(.leading, 28)
                .animation(.easeInOut(duration: 0.4), value: selectedType)
            }
        }
        .onAppear {
            updateTimeDateFromHoursAndMinutes()
            if selectedType == .count && countGoal > 0 {
                countText = String(countGoal)
            }
        }
        .onChange(of: selectedType) { _, newValue in
            if newValue == .count {
                if countGoal > 0 {
                    countText = String(countGoal)
                } else {
                    countText = ""
                    countGoal = 0
                }
            } else {
                if hours == 0 && minutes == 0 {
                    hours = 1
                    minutes = 0
                }
                updateTimeDateFromHoursAndMinutes()
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
