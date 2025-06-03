import Foundation
import SwiftData

/// Поставщик сервисов трекинга привычек
final class ProgressServiceProvider: ProgressTrackingServiceProvider {
    /// Получение сервиса для конкретного типа привычки (глобальный синглтон)
    static func getService(for habitType: HabitType) -> ProgressTrackingService {
        switch habitType {
        case .count:
            return HabitCounterService.shared
        case .time:
            return HabitTimerService.shared
        }
    }
    
    /// Получение сервиса для привычки (глобальный синглтон)
    static func getService(for habit: Habit) -> ProgressTrackingService {
        return getService(for: habit.type)
    }
    
    /// Получение локального сервиса для конкретной даты и привычки
    static func getLocalService(
        for habit: Habit,
        date: Date,
        initialProgress: Int,
        onUpdate: @escaping () -> Void
    ) -> ProgressTrackingService {
        if habit.type == .time && !Calendar.current.isDateInToday(date) {
            // Для привычек типа "время" в прошлых датах используем локальный сервис
            return PastDateTimerService(
                initialProgress: initialProgress,
                habitId: habit.uuid.uuidString,
                onUpdate: onUpdate
            )
        } else {
            // Для остальных случаев возвращаем глобальный сервис
            return getService(for: habit)
        }
    }
}
