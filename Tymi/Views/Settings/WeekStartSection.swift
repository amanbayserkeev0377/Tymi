import SwiftUI

struct WeekStartOption: Identifiable {
    let id: Int
    let name: String
    let value: Int
    
    static func formatDayName(_ name: String) -> String {
        guard !name.isEmpty else { return name }
        return name.prefix(1).uppercased() + name.dropFirst().lowercased()
    }
    
    static let system = WeekStartOption(
        id: 0,
        name: "week_start_system".localized,
        value: 0
    )
    
    static let sunday = WeekStartOption(
        id: 1,
        name: formatDayName(Weekday.sunday.fullName),
        value: 1 // Воскресенье = 1 (системная константа)
    )
    
    static let monday = WeekStartOption(
        id: 2,
        name: formatDayName(Weekday.monday.fullName),
        value: 2 // Понедельник = 2 (системная константа)
    )
    
    static let allOptions = [system, sunday, monday]
}

struct WeekStartSection: View {
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek: Int = 0
    @StateObject private var calendarManager = CalendarManager.shared
    
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
                        NotificationCenter.default.post(
                            name: Notification.Name("FirstDayOfWeekChanged"),
                            object: nil,
                            userInfo: ["firstDayOfWeek": option.value]
                        )
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
        
        // Преобразуем значение в индекс (0-6)
        let weekdayIndex = firstDayOfWeek - 1
        let weekday = Weekday(rawValue: weekdayIndex) ?? .sunday
        return WeekStartOption.formatDayName(weekday.fullName)
    }
}

#Preview {
    WeekStartSection()
        .padding()
}
