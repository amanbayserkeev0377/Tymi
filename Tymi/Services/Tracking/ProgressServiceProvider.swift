import Foundation

/// Поставщик сервисов трекинга привычек
final class ProgressServiceProvider: ProgressTrackingServiceProvider {
    /// Получение сервиса для конкретного типа привычки
    static func getService(for habitType: HabitType) -> ProgressTrackingService {
        switch habitType {
        case .count:
            return HabitCounterService.shared
        case .time:
            return HabitTimerService.shared
        }
    }
    
    /// Получение сервиса для привычки
    static func getService(for habit: Habit) -> ProgressTrackingService {
        return getService(for: habit.type)
    }
}
