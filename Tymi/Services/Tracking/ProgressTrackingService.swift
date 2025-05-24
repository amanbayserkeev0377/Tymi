import Foundation
import SwiftData

/// Протокол для сервисов отслеживания прогресса привычек
protocol ProgressTrackingService: Observable {
    /// Прогресс для всех привычек (ключ - ID привычки, значение - прогресс)
    var progressUpdates: [String: Int] { get }
    
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
}

/// Протокол для поставщика сервисов трекинга
protocol ProgressTrackingServiceProvider {
    /// Получение сервиса для конкретного типа привычки
    static func getService(for habitType: HabitType) -> ProgressTrackingService
    
    /// Получение сервиса для привычки
    static func getService(for habit: Habit) -> ProgressTrackingService
}

extension ProgressTrackingService {
    func persistCompletions(for habitId: String, in modelContext: ModelContext, date: Date = .now) {
        let currentProgress = getCurrentProgress(for: habitId)
        
        guard currentProgress > 0 else {
            return
        }
        
        do {
            guard let uuid = UUID(uuidString: habitId) else {
                return
            }
            
            // Ищем привычку с минимальным запросом
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.uuid == uuid })
            let habits = try modelContext.fetch(descriptor)
            
            guard let habit = habits.first else {
                return
            }
            
            // Проверяем, изменился ли прогресс, чтобы избежать лишних обновлений
            let existingProgress = habit.progressForDate(date)
            
            if currentProgress == existingProgress {
                return
            }
            
            // ИСПРАВЛЕНО: добавляем проверку на nil
            guard let completions = habit.completions else {
                // Если completions == nil, создаем новый массив
                habit.completions = []
                
                if currentProgress > 0 {
                    let newCompletion = HabitCompletion(
                        date: date,
                        value: currentProgress,
                        habit: habit
                    )
                    habit.completions?.append(newCompletion)
                }
                try modelContext.save()
                return
            }
            
            // Группируем операции удаления и добавления с try
            try modelContext.transaction {
                // ИСПРАВЛЕНО: используем проверенную переменную completions
                let oldCompletions = completions.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: date)
                }
                
                for completion in oldCompletions {
                    modelContext.delete(completion)
                }
                
                // Добавляем новую запись
                if currentProgress > 0 {
                    let newCompletion = HabitCompletion(
                        date: date,
                        value: currentProgress,
                        habit: habit
                    )
                    habit.completions?.append(newCompletion)
                }
            }
            
            try modelContext.save()
        } catch {
            print("DEBUG: Error persisting progress: \(error)")
        }
    }
    
    // И соответственно изменить persistAllCompletionsToSwiftData
    func persistAllCompletionsToSwiftData(modelContext: ModelContext) {
        for (habitId, _) in progressUpdates {
            persistCompletions(for: habitId, in: modelContext, date: Date())
        }
    }
}
