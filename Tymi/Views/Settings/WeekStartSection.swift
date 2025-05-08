import SwiftUI

struct WeekStartOption: Identifiable {
    let id: Int
    let name: String
    let value: Int
    
    static let system = WeekStartOption(
        id: 0,
        name: "week_start_system".localized,
        value: 0
    )
    
    static var monday: WeekStartOption {
        let name = Calendar.current.weekdaySymbols[1] // Понедельник - индекс 1
        return WeekStartOption(id: 1, name: name, value: 2)
    }
    
    static var saturday: WeekStartOption {
        let name = Calendar.current.weekdaySymbols[6] // Суббота - индекс 6
        return WeekStartOption(id: 2, name: name, value: 7)
    }
    
    static var sunday: WeekStartOption {
        let name = Calendar.current.weekdaySymbols[0] // Воскресенье - индекс 0
        return WeekStartOption(id: 3, name: name, value: 1)
    }
    
    static var allOptions: [WeekStartOption] {
        [system, monday, saturday, sunday]
    }
}

struct WeekStartSection: View {
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek: Int = 0
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
            
            Text("week_start_day".localized)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Menu {
                ForEach(WeekStartOption.allOptions) { option in
                    Button(action: {
                        firstDayOfWeek = option.value
                        Weekday.updateFirstWeekdayNotification()
                    }) {
                        HStack {
                            Text(option.name)
                            if option.value == firstDayOfWeek {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(getSelectedDayName())
                    Image(systemName: "chevron.up.chevron.down")
                }
                .foregroundStyle(.secondary)
            }
            .tint(.primary)
        }
    }
    
    private func getSelectedDayName() -> String {
        if firstDayOfWeek == 0 {
            return WeekStartOption.system.name
        }
        
        return WeekStartOption.allOptions.first { $0.value == firstDayOfWeek }?.name ?? WeekStartOption.system.name
    }
}

#Preview {
    WeekStartSection()
        .padding()
}
