import Foundation

enum Weekday: Int, CaseIterable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
    
    static func from(date: Date) -> Weekday {
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: date) - 1
        return Weekday(rawValue: weekdayNumber) ?? .sunday
    }
    
    static var orderedByUserPreference: [Weekday] {
        let userDefaults = UserDefaults.standard
        let firstWeekday = userDefaults.integer(forKey: "firstDayOfWeek")
        
        let effectiveFirstWeekday = firstWeekday > 0 ? firstWeekday : Calendar.current.firstWeekday
        
        let firstWeekdayIndex = effectiveFirstWeekday - 1
        
        let weekdays = Weekday.allCases
        let before = Array(weekdays[firstWeekdayIndex...])
        let after = Array(weekdays[..<firstWeekdayIndex])
        
        return before + after
    }
    
    var shortName: String {
        let calendar = Calendar.current
        return calendar.shortWeekdaySymbols[self.rawValue]
    }
    
    var fullName: String {
        let calendar = Calendar.current
        return calendar.weekdaySymbols[self.rawValue]
    }
}
