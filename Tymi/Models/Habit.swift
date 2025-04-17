import Foundation
import SwiftData

@Model
final class Habit {
    // Basic properties
    var title: String
    var type: HabitType
    var goal: Int // Target value (count or seconds for time)
    
    // System properties
    var createdAt: Date
    var isArchived: Bool
    
    // Relationship with completions (one-to-many)
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]
    
    // Settings for days and reminders
    var activeDays: [Bool]
    var reminderTime: Date?
    var startDate: Date
    
    // Helper to create active days array
    static func createDefaultActiveDays() -> [Bool] {
        return Array(repeating: true, count: 7)
    }
    
    // Initializer with default values
    init(
        title: String,
        type: HabitType = .count,
        goal: Int = 1,
        createdAt: Date = .now,
        isArchived: Bool = false,
        activeDays: [Bool]? = nil,
        reminderTime: Date? = nil,
        startDate: Date = .now
    ) {
        self.title = title
        self.type = type
        self.goal = goal
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.completions = []
        self.activeDays = activeDays ?? Habit.createDefaultActiveDays()
        self.reminderTime = reminderTime
        self.startDate = startDate
    }
    
    // Get progress for specific date
    func progressForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        
        return completions
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.value }
    }
    
    // Format progress based on habit type
    func formattedProgress(for date: Date) -> String {
        let progress = progressForDate(date)
        
        switch type {
        case .count:
            return "\(progress)/\(goal)"
        case .time:
            if progress == 0 {
                return "0:00:00"
            }
            
            let hours = progress / 3600
            let minutes = (progress % 3600) / 60
            let seconds = progress % 60
            
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    // Format goal based on habit type
    var formattedGoal: String {
        switch type {
        case .count:
            return "\(goal) times"
        case .time:
            let hours = goal / 3600
            let minutes = (goal % 3600) / 60
            
            if hours > 0 {
                return "\(hours) hr \(minutes) min"
            } else {
                return "\(minutes) min"
            }
        }
    }
    
    // Check if habit is active on specific day of week
    func isActiveOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // Get first day of week from user's calendar settings
        let firstWeekday = calendar.firstWeekday
        
        // Calculate index in activeDays array based on system first day of week
        let dayIndex = (weekday + 7 - firstWeekday) % 7
        return activeDays[dayIndex]
    }
    
    // Check if habit is completed for the day
    func isCompletedForDate(_ date: Date) -> Bool {
        return progressForDate(date) >= goal
    }
    
    // Calculate completion percentage for the day
    func completionPercentageForDate(_ date: Date) -> Double {
        let progress = progressForDate(date)
        
        if goal <= 0 {
            return progress > 0 ? 1.0 : 0.0
        }
        
        let percentage = Double(progress) / Double(goal)
        return min(percentage, 1.0) // Cap at 100%
    }
    
    // Add progress value
    func addProgress(_ value: Int, for date: Date = .now) {
        let completion = HabitCompletion(date: date, value: value, habit: self)
        completions.append(completion)
    }
}
