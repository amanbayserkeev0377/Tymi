import Foundation

struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Int
    let goal: Int
    let habit: Habit
    
    // Equatable implementation
    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        return lhs.id == rhs.id
    }
    
    var completionPercentage: Double {
        guard goal > 0 else { return 0 }
        return Double(value) / Double(goal)
    }
    
    var isCompleted: Bool {
        value >= goal
    }
    
    var isOverAchieved: Bool {
        value > goal
    }
    
    var formattedValue: String {
        switch habit.type {
        case .count:
            return "\(value)"
        case .time:
            return value.formattedAsTime()
        }
    }
    
    var formattedGoal: String {
        switch habit.type {
        case .count:
            return "\(goal)"
        case .time:
            return goal.formattedAsTime()
        }
    }
    
    // Форматирование времени без секунд для графиков
    var formattedValueWithoutSeconds: String {
        switch habit.type {
        case .count:
            return "\(value)"
        case .time:
            let hours = value / 3600
            let minutes = (value % 3600) / 60
            
            if hours > 0 {
                return String(format: "%d:%02d", hours, minutes)
            } else if minutes > 0 {
                return String(format: "%d min", minutes)
            } else {
                return "0"
            }
        }
    }
}
