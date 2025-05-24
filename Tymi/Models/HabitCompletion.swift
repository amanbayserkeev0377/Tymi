import Foundation
import SwiftData

@Model
final class HabitCompletion {
    var date: Date = Date()
    var value: Int = 0
    
    // Relationship with Habit
    var habit: Habit?
    
    // MARK: - Initializers
    
    init(date: Date = Date(), value: Int = 0, habit: Habit? = nil) {
        self.date = date
        self.value = value
        self.habit = habit
    }
    
    // MARK: - Time Habit Helpers

    // Get formatted time string (HH:MM:SS)
    var formattedTime: String {
        return value.formattedAsTime()
    }
    
    // Add minutes to current value
    func addMinutes(_ minutes: Int) {
        value += minutes * 60
    }
    
    // Time components
    var hours: Int { value / 3600 }
    var minutes: Int { (value % 3600) / 60 }
    var seconds: Int { value % 60 }
    
    // Convert from hours/minutes/seconds to total seconds
    static func secondsFrom(hours: Int, minutes: Int, seconds: Int = 0) -> Int {
        return (hours * 3600) + (minutes * 60) + seconds
    }
}
