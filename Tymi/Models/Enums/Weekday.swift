import Foundation

enum Weekday: Int, CaseIterable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
    
    static func from(date: Date) -> Weekday {
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: date) - 1
        return Weekday(rawValue: weekdayNumber) ?? .sunday
    }
    
    static var orderedByUserPreference: [Weekday] {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday - 1
        
        let weekdays = Weekday.allCases
        let before = Array(weekdays[firstWeekday...])
        let after = Array(weekdays[..<firstWeekday])
        
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
