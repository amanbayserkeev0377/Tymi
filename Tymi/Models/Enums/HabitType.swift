import Foundation

enum HabitType: Int, Codable, CaseIterable {
    case count
    case time
    
    var name: String {
        switch self {
        case .count:
            return "Count"
        case .time:
            return "Time"
        }
    }
    
    var defaultGoal: Int {
        switch self {
        case .count:
            return 0 // defaults is 0 time
        case .time:
            return 60 // default is 60 minutes
        }
    }
}
