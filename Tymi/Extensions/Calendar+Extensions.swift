import Foundation

extension Calendar {
    func isDateInFuture(_ date: Date) -> Bool {
        let today = startOfDay(for: Date())
        let compareDate = startOfDay(for: date)
        return compareDate > today
    }
} 