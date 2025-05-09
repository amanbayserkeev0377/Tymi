import Foundation
import SwiftData

/// Протокол для сервисов отслеживания прогресса привычек
protocol ProgressTrackingService: Observable {
    /// Получение текущего прогресса для привычки
    func getCurrentProgress(for habitId: String) -> Int
    
    /// Добавление прогресса к привычке (положительное или отрицательное значение)
    func addProgress(_ value: Int, for habitId: String)
    
    /// Сброс прогресса для привычки
    func resetProgress(for habitId: String)
    
    /// Проверка, запущен ли таймер (для привычек типа time)
    func isTimerRunning(for habitId: String) -> Bool
    
    /// Запуск таймера (для привычек типа time)
    func startTimer(for habitId: String, initialProgress: Int)
    
    /// Остановка таймера (для привычек типа time)
    func stopTimer(for habitId: String)
    
    /// Сохранение прогресса в базу данных SwiftData
    func persistCompletions(for habitId: String, in modelContext: ModelContext, date: Date)
    
    /// Сохранение всех прогрессов в базу данных SwiftData
    func persistAllCompletionsToSwiftData(modelContext: ModelContext)
    
    /// Асинхронный поток обновлений прогресса
    var progressUpdatesSequence: AsyncStream<[String: Int]> { get }
    
    /// Асинхронный поток уведомлений об изменениях
    var objectWillChangeSequence: AsyncStream<Void> { get }
}

/// Протокол для поставщика сервисов трекинга
protocol ProgressTrackingServiceProvider {
    /// Получение сервиса для конкретного типа привычки
    static func getService(for habitType: HabitType) -> ProgressTrackingService
    
    /// Получение сервиса для привычки
    static func getService(for habit: Habit) -> ProgressTrackingService
}
