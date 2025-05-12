import SwiftUI

struct ActiveDaysSection: View {
    @Binding var activeDays: [Bool]
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek: Int = 0
    
    private var calendar: Calendar {
        return Calendar.userPreferred
    }
    
    private var activeDaysDescription: String {
        let allActive = activeDays.allSatisfy { $0 }
        let noneActive = activeDays.allSatisfy { !$0 }
        
        if allActive {
            return "everyday".localized
        } else if noneActive {
            return "no_days_selected".localized
        } else {
            let weekdays = calendar.orderedWeekdaySymbols
            let activeDayNames = activeDays.enumerated()
                .filter { $0.element }
                .map { weekdays[$0.offset] }
            
            return activeDayNames.joined(separator: ", ")
        }
    }

    var body: some View {
        NavigationLink(destination: ActiveDaysSelectionView(activeDays: $activeDays)) {
            HStack {
                Image(systemName: "cloud.sun")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .accessibilityHidden(true)
                
                Text("active_days".localized)
                
                Spacer()
                
                Text(activeDaysDescription)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}

struct ActiveDaysSelectionView: View {
    @Binding var activeDays: [Bool]
    @Environment(\.dismiss) private var dismiss
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    private var weekdaySymbols: [String] {
        calendar.orderedWeekdaySymbols
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    // Установить все дни
                    withAnimation {
                        activeDays = Array(repeating: true, count: 7)
                    }
                } label: {
                    HStack {
                        Text("select_all_days".localized)
                        Spacer()
                        if activeDays.allSatisfy({ $0 }) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    // Только будние дни
                    withAnimation {
                        let weekdays = Weekday.orderedByUserPreference
                        activeDays = weekdays.map { !$0.isWeekend }
                    }
                } label: {
                    HStack {
                        Text("weekdays_only".localized)
                        Spacer()
                        if activeDays.enumerated().allSatisfy({ (index, isActive) in
                            let weekday = Weekday.orderedByUserPreference[index]
                            return isActive == !weekday.isWeekend
                        }) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    // Только выходные
                    withAnimation {
                        let weekdays = Weekday.orderedByUserPreference
                        activeDays = weekdays.map { $0.isWeekend }
                    }
                } label: {
                    HStack {
                        Text("weekends_only".localized)
                        Spacer()
                        if activeDays.enumerated().allSatisfy({ (index, isActive) in
                            let weekday = Weekday.orderedByUserPreference[index]
                            return isActive == weekday.isWeekend
                        }) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Section(header: Text("choose_individual_days".localized)) {
                ForEach(0..<7) { index in
                    Button {
                        withAnimation {
                            activeDays[index].toggle()
                        }
                    } label: {
                        HStack {
                            Text(weekdaySymbols[index])
                            Spacer()
                            if activeDays[index] {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("active_days".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: activeDays) { oldValue, newValue in
            // Проверка, что выбран хотя бы один день
            if newValue.allSatisfy({ !$0 }) {
                // Если все дни сняты, восстанавливаем предыдущее состояние
                activeDays = oldValue
            }
        }
    }
}

// СТРОКИ ДЛЯ ЛОКАЛИЗАЦИИ:
/*
"everyday" = "Ежедневно";
"no_days_selected" = "Не выбрано";
"active_days" = "Активные дни";
"select_all_days" = "Все дни";
"weekdays_only" = "Только будни";
"weekends_only" = "Только выходные";
"choose_individual_days" = "Выбрать отдельные дни";
*/
