import SwiftUI

struct GoalSection: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    
    @State private var countText = ""
    @FocusState private var isCountFieldFocused: Bool
    
    private var formattedTimeGoal: String {
        var parts: [String] = []
        
        if hours > 0 {
            parts.append("\(hours) \("hr".localized)")
        }
        
        if minutes > 0 || hours == 0 {
            parts.append("\(minutes) \("min".localized)")
        }
        
        return parts.joined(separator: " ")
    }
    
    var body: some View {
        Section {
            // Тип привычки
            Picker("habit_type".localized, selection: $selectedType) {
                Text("count".localized).tag(HabitType.count)
                Text("time".localized).tag(HabitType.time)
            }
            
            // Содержимое зависит от выбранного типа
            if selectedType == .count {
                // Для числовой привычки - прямой ввод
                HStack {
                    Text("goal".localized)
                    Spacer()
                    TextField("count".localized, text: $countText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isCountFieldFocused)
                        .frame(width: 100)
                        .onChange(of: countText) { _, newValue in
                            if let value = Int(newValue), value > 0 {
                                countGoal = min(value, 999999)
                            } else if newValue.isEmpty {
                                // Оставляем пустое поле, но не обнуляем цель
                            } else {
                                // Если введен неверный формат, восстанавливаем предыдущее значение
                                countText = "\(countGoal)"
                            }
                        }
                }
                .onAppear {
                    // Инициализируем текстовое поле при появлении
                    countText = "\(countGoal)"
                }
                .onChange(of: selectedType) { _, type in
                    if type == .count {
                        countText = "\(countGoal)"
                    }
                }
            } else {
                // Для привычки с временем - навигация к выбору
                NavigationLink(destination: TimeGoalView(hours: $hours, minutes: $minutes)) {
                    HStack {
                        Text("goal".localized)
                        Spacer()
                        Text(formattedTimeGoal)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("done".localized) {
                    isCountFieldFocused = false
                }
            }
        }
    }
}

struct TimeGoalView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Environment(\.dismiss) private var dismiss
    
    // Предопределенные значения для быстрого выбора в минутах
    private let presetValues = [
        5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240
    ]
    
    var body: some View {
        List {
            Section(header: Text("quick_select".localized)) {
                ForEach(presetValues, id: \.self) { value in
                    Button {
                        // Конвертируем минуты в часы и минуты
                        hours = value / 60
                        minutes = value % 60
                        dismiss()
                    } label: {
                        HStack {
                            if value < 60 {
                                Text("\(value) \("min".localized)")
                            } else {
                                let hrs = value / 60
                                let mins = value % 60
                                
                                if mins == 0 {
                                    Text("\(hrs) \("hr".localized)")
                                } else {
                                    Text("\(hrs) \("hr".localized) \(mins) \("min".localized)")
                                }
                            }
                            
                            Spacer()
                            
                            // Отображаем галочку у текущего значения
                            if hours * 60 + minutes == value {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("custom_time".localized)) {
                HStack {
                    Picker("", selection: $hours) {
                        ForEach(0..<25) { hour in
                            Text("\(hour) \("hr".localized)").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    
                    Picker("", selection: $minutes) {
                        ForEach(0..<60) { minute in
                            Text("\(minute) \("min".localized)").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .frame(height: 150)
                
                Button {
                    dismiss()
                } label: {
                    Text("set_custom_time".localized)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(hours == 0 && minutes == 0)
            }
        }
        .navigationTitle("set_time_goal".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
