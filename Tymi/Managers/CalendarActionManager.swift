import Foundation
import SwiftUI

@Observable
final class CalendarActionManager {
    enum ActionType {
        case complete
        case addProgress
    }
    
    var actionType: ActionType?
    var habit: Habit?
    var date: Date?
    
    func requestAction(_ type: ActionType, habit: Habit, date: Date) {
        self.actionType = type
        self.habit = habit
        self.date = date
    }
    
    func clear() {
        actionType = nil
        habit = nil
        date = nil
    }
}
