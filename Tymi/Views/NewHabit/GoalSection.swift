import SwiftUI

struct GoalSection: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    
    @State private var timeDate: Date = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var countText: String = ""
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(
                        title: { Text("daily_goal".localized) },
                        icon: {
                            Image(systemName: "trophy")
                                .font(.body)
                                .symbolEffect(.bounce, options: .repeat(1), value: selectedType)
                                .accessibilityHidden(true)
                        }
                    )
                    
                    Spacer()
                    
                    // Сегментированный переключатель типа
                    Picker("", selection: $selectedType.animation(.easeInOut(duration: 0.4))) {
                        Text("count".localized).tag(HabitType.count)
                        Text("time".localized).tag(HabitType.time)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 170)
                }
                
                // Кастомный разделитель
                Divider()
                
                // Используем отдельное управление состоянием для анимации
                ZStack(alignment: .leading) {
                    // Count field - всегда непосредственно под заголовком
                    TextField("goalsection_enter_count".localized, text: $countText)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .onChange(of: countText) { _, newValue in
                            if let number = Int(newValue), number > 0 {
                                countGoal = min(number, 999999)
                            } else if newValue.isEmpty {
                                // Оставляем пустое поле без сброса значения
                            }
                        }
                        .opacity(selectedType == .count ? 1 : 0)
                        .offset(x: selectedType == .count ? 0 : -10)
                        .accessibilityHidden(selectedType != .count)
                    
                    // Time field - с иконкой часов
                    HStack {
                        Label(
                            title: {
                                Text("goalsection_choose_time".localized)
                                    .foregroundStyle(.secondary)
                            },
                            icon: {
                                Image(systemName: "clock")
                            }
                        )
                        
                        Spacer()
                        
                        DatePicker("", selection: $timeDate, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .onChange(of: timeDate) { _, _ in
                                updateHoursAndMinutesFromTimeDate()
                            }
                    }
                    .opacity(selectedType == .time ? 1 : 0)
                    .offset(x: selectedType == .time ? 0 : 10)
                    .accessibilityHidden(selectedType != .time)
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            initializeValues()
        }
        .onChange(of: selectedType) { _, newValue in
            resetFieldsForType(newValue)
        }
    }

    
    // Инициализация значений при появлении
    private func initializeValues() {
        updateTimeDateFromHoursAndMinutes()
        
        if selectedType == .count {
            if countGoal <= 0 {
                countGoal = 1
            }
            countText = String(countGoal)
        } else {
            if hours == 0 && minutes == 0 {
                hours = 1
                minutes = 0
                updateTimeDateFromHoursAndMinutes()
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
            updateTimeDateFromHoursAndMinutes()
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
}
