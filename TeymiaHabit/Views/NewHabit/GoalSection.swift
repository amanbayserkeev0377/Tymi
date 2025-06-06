import SwiftUI

struct GoalSection: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    @FocusState.Binding var isFocused: Bool
    
    @State private var countText: String = ""
    @State private var timeDate: Date = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "trophy")
                    .foregroundStyle(AppColorManager.shared.selectedColor.color)
                    .font(.system(size: 20))
                    .symbolEffect(.bounce, options: .repeat(1), value: selectedType)
                    .frame(width: 30)
                Text("daily_goal".localized)
                
                Spacer()
                
                Picker("", selection: $selectedType.animation(.easeInOut(duration: 0.4))) {
                    Text("count".localized).tag(HabitType.count)
                    Text("time".localized).tag(HabitType.time)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 170)
            }
            
            // Компонент ввода в зависимости от типа
            if selectedType == .count {
                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundStyle(AppColorManager.shared.selectedColor.color.opacity(0.5))
                        .font(.system(size: 22))
                        .frame(width: 30)
                        .clipped()
                    
                    TextField("goalsection_enter_count".localized, text: $countText)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .multilineTextAlignment(.leading)
                        .onChange(of: countText) { _, newValue in
                            if let number = Int(newValue), number > 0 {
                                countGoal = min(number, 999999)
                            }
                        }
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .foregroundStyle(AppColorManager.shared.selectedColor.color.opacity(0.5))
                        .font(.system(size: 22))
                        .frame(width: 30)
                        .clipped()
                    
                    Text("goalsection_choose_time".localized)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $timeDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: timeDate) { _, _ in
                            updateHoursAndMinutesFromTimeDate()
                        }
                }
            }
        }
        .onAppear {
            initializeValues()
        }
        .onChange(of: selectedType) { _, newValue in
            resetFieldsForType(newValue)
        }
    }
    
    // Синхронизация между timeDate и часами/минутами
    private func updateHoursAndMinutesFromTimeDate() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: timeDate)
        hours = components.hour ?? 0
        minutes = components.minute ?? 0
    }
    
    private func updateTimeDateFromHoursAndMinutes() {
        timeDate = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date()) ?? Date()
    }
    
    // Инициализация значений при появлении
    private func initializeValues() {
        if selectedType == .count {
            if countGoal <= 0 {
                countGoal = 1
            }
            countText = String(countGoal)
        } else {
            if hours == 0 && minutes == 0 {
                hours = 1
                minutes = 0
            }
        }
    }
    
    // Сброс полей при смене типа
    private func resetFieldsForType(_ type: HabitType) {
        if type == .count {
            if countGoal <= 0 {
                countGoal = 1
            }
            countText = String(countGoal)
        } else {
            if hours == 0 && minutes == 0 {
                hours = 1
                minutes = 0
            }
        }
    }
}
