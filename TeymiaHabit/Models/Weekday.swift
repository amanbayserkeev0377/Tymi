import Foundation

@Observable
class WeekdayPreferences {
    static let shared = WeekdayPreferences()
    
    // Хранение непосредственно в классе для Observable
    private(set) var firstDayOfWeek: Int
    
    // Приватный инициализатор для синглтона
    private init() {
        self.firstDayOfWeek = UserDefaults.standard.integer(forKey: "firstDayOfWeek")
    }
    
    // Метод изменения значения
    func updateFirstDayOfWeek(_ value: Int) {
        self.firstDayOfWeek = value
        UserDefaults.standard.set(value, forKey: "firstDayOfWeek")
    }
}

enum Weekday: Int, CaseIterable, Hashable, Sendable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7
    
    static func from(date: Date) -> Weekday {
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: date)
        return Weekday(rawValue: weekdayNumber) ?? .sunday
    }
    
    static var orderedByUserPreference: [Weekday] {
        Calendar.userPreferred.weekdays
    }
    
    var shortName: String {
        Calendar.current.shortWeekdaySymbols[self.rawValue - 1]
    }
    
    var fullName: String {
        Calendar.current.weekdaySymbols[self.rawValue - 1]
    }
    
    var arrayIndex: Int { self.rawValue - 1 }
    
    var isWeekend: Bool { self == .saturday || self == .sunday }
    
    var next: Weekday {
        Weekday(rawValue: (self.rawValue % 7) + 1) ?? .sunday
    }
    
    var previous: Weekday {
        Weekday(rawValue: self.rawValue == 1 ? 7 : self.rawValue - 1) ?? .sunday
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let firstDayOfWeekChanged = Notification.Name("FirstDayOfWeekChanged")
}

// MARK: - Calendar Extension

extension Calendar {
    /// Создает календарь с учетом пользовательских настроек
    static var userPreferred: Calendar {
        let firstDayOfWeek = WeekdayPreferences.shared.firstDayOfWeek
        
        var calendar = Calendar.current
        // Явно устанавливаем часовой пояс пользователя
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = firstDayOfWeek == 0 ? calendar.firstWeekday : firstDayOfWeek
        
        return calendar
    }
    
    /// Возвращает упорядоченный список дней недели с учетом первого дня недели
    var weekdays: [Weekday] {
        let weekdayValueOfFirst = self.firstWeekday
        let allWeekdays = Weekday.allCases
        
        // Находим индекс первого дня недели
        guard let firstWeekdayIndex = allWeekdays.firstIndex(where: { $0.rawValue == weekdayValueOfFirst }) else {
            return Array(allWeekdays)
        }
        
        // Создаем новый массив и заполняем его с учетом порядка
        var result = [Weekday]()
        for i in 0..<allWeekdays.count {
            let index = (firstWeekdayIndex + i) % allWeekdays.count
            result.append(allWeekdays[index])
        }
        
        return result
    }
    
    /// Возвращает короткие символы дней недели, упорядоченные по первому дню недели
    var orderedShortWeekdaySymbols: [String] {
        let allSymbols = self.shortWeekdaySymbols
        return (0..<7).map { allSymbols[(($0 + self.firstWeekday - 1) % 7)] }
    }
    
    /// Возвращает форматированные полные названия дней недели (первая буква заглавная)
    var orderedFormattedFullWeekdaySymbols: [String] {
        orderedWeekdaySymbols.map { $0.capitalized }
    }
    
    /// Возвращает короткие символы дней недели (1 буква)
    var orderedWeekdayInitials: [String] {
        orderedShortWeekdaySymbols.map { $0.prefix(1).uppercased() }
    }
    
    /// Возвращает полные названия дней недели, упорядоченные по первому дню недели
    var orderedWeekdaySymbols: [String] {
        let allSymbols = self.weekdaySymbols
        return (0..<7).map { allSymbols[(($0 + self.firstWeekday - 1) % 7)] }
    }
    
    /// Возвращает стилизованные короткие названия дней (первая буква заглавная)
    var orderedFormattedWeekdaySymbols: [String] {
        orderedShortWeekdaySymbols.map { $0.capitalized }
    }
    
    /// Преобразует индекс в массиве упорядоченных дней в системный индекс дня недели
    func systemWeekdayFromOrdered(index: Int) -> Int {
        (index + self.firstWeekday - 1) % 7 + 1
    }
}
