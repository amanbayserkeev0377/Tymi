import Foundation

extension Int {
    /// Formats seconds to a string like "1:30:45" (hours:minutes:seconds)
    func formattedAsTime() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// Formats seconds to a string like "1 hr 30 min" or "30 min"
    func formattedAsDuration() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
    
    /// Formats current value and total value to display progress, e.g. "10/20"
    func formattedAsProgress(total: Int) -> String {
        return "\(self)/\(total)"
    }
}

// Extension for Date with useful formatting methods
extension Date {
    /// Gets the weekday name (Monday, Tuesday, etc.)
    var weekdayName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self)
    }
    
    /// Formats date to a string like "January 1"
    var formattedDayMonth: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        return dateFormatter.string(from: self)
    }
    
    /// Checks if the date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Checks if the date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
}
