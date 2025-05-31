import SwiftUI

struct WeekStartSection: View {
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    @State private var selection: Int
    
    init() {
        // Инициализируем локальное состояние выбора из общего значения
        _selection = State(initialValue: WeekdayPreferences.shared.firstDayOfWeek)
    }
    
    // Локализованные названия дней недели с правильной капитализацией
    private var localizedWeekdays: [(name: String, value: Int)] {
        // Создаем календарь
        let calendar = Calendar.current
        let today = Date()
        
        // Получаем даты для нужных дней недели
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Полное название дня недели
        
        // Определяем текущий день недели
        let weekday = calendar.component(.weekday, from: today)
        
        // Вычисляем смещения для получения дат дней недели
        let sundayOffset = weekday == 1 ? 0 : -(weekday - 1)
        let mondayOffset = weekday == 2 ? 0 : (weekday > 2 ? -(weekday - 2) : 1)
        let saturdayOffset = weekday == 7 ? 0 : (weekday < 7 ? 7 - weekday : -1)
        
        // Получаем даты для конкретных дней недели
        let sundayDate = calendar.date(byAdding: .day, value: sundayOffset, to: today)!
        let mondayDate = calendar.date(byAdding: .day, value: mondayOffset, to: today)!
        let saturdayDate = calendar.date(byAdding: .day, value: saturdayOffset, to: today)!
        
        // Получаем локализованные названия с правильной капитализацией
        let sundayName = dateFormatter.string(from: sundayDate).capitalized
        let mondayName = dateFormatter.string(from: mondayDate).capitalized
        let saturdayName = dateFormatter.string(from: saturdayDate).capitalized
        
        return [
            ("week_start_system".localized, 0),   // System default
            (saturdayName, 7),                    // Saturday
            (sundayName, 1),                      // Sunday
            (mondayName, 2)                       // Monday
        ]
    }
    
    var body: some View {
        HStack {
            Label(
                title: { Text("week_start_day".localized) },
                icon: {
                    Image(systemName: "calendar")
                        .withIOSSettingsIcon(lightColors: [
                            Color(#colorLiteral(red: 0.75, green: 0.65, blue: 0.55, alpha: 1)),
                            Color(#colorLiteral(red: 0.4, green: 0.35, blue: 0.3, alpha: 1))
                        ])
                }
            )
            
            Spacer()
            
            // Показываем текущий выбор дня начала недели с меню
            Menu {
                ForEach(localizedWeekdays, id: \.value) { weekday in
                    Button {
                        selection = weekday.value
                        weekdayPrefs.updateFirstDayOfWeek(weekday.value)
                    } label: {
                        Text(weekday.name)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    // Показываем текущий выбранный день
                    Text(localizedWeekdays.first(where: { $0.value == selection })?.name ?? "")
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
            }
            .tint(.primary)
        }
    }
}
