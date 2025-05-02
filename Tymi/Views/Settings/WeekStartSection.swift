import SwiftUI

struct WeekStartOption {
    let name: String
    let value: Int
    
    static func formatDayName(_ name: String) -> String {
        guard !name.isEmpty else { return name }
        return name.prefix(1).uppercased() + name.dropFirst().lowercased()
    }
    
    static let system = WeekStartOption(name: "week_start_system".localized, value: 0)
    
    static let sunday = WeekStartOption(
        name: formatDayName(Weekday.sunday.fullName),
        value: 7
    )
    
    static let monday = WeekStartOption(
        name: formatDayName(Weekday.monday.fullName),
        value: 1
    )
    
    static let allOptions = [system, sunday, monday]
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
                ForEach(WeekStartOption.allOptions, id: \.value) { option in
                    Button(action: {
                        firstDayOfWeek = option.value
                        NotificationCenter.default.post(name: Notification.Name("FirstDayOfWeekChanged"), object: nil)
                    }) {
                        HStack {
                            Text(option.name)
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
        WeekStartOption.allOptions.first { $0.value == firstDayOfWeek }?.name ?? WeekStartOption.system.name
    }
}

#Preview {
    WeekStartSection()
        .padding()
}
