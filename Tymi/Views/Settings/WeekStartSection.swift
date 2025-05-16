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
        let name = Calendar.current.weekdaySymbols[1]
        return WeekStartOption(id: 1, name: name, value: 2)
    }
    
    static var saturday: WeekStartOption {
        let name = Calendar.current.weekdaySymbols[6]
        return WeekStartOption(id: 2, name: name, value: 7)
    }
    
    static var sunday: WeekStartOption {
        let name = Calendar.current.weekdaySymbols[0]
        return WeekStartOption(id: 3, name: name, value: 1)
    }
    
    static var allOptions: [WeekStartOption] {
        [system, monday, saturday, sunday]
    }
}

struct WeekStartSection: View {
    @State private var weekdayPrefs = WeekdayPreferences.shared
    
    var body: some View {
        Picker(selection: $weekdayPrefs.firstDayOfWeek, label:
            Label(
                title: { Text("week_start_day".localized) },
                icon: { Image(systemName: "calendar")
                }
            )
        ) {
            ForEach(WeekStartOption.allOptions) { option in
                Text(option.name).tag(option.value)
            }
        }
    }
}
