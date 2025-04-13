import Foundation

/// Протокол для работы с данными прогресса привычек
protocol HabitDataStore {
    /// Сохраняет прогресс привычки
    func saveProgress(_ progress: HabitProgress)
    
    /// Получает прогресс привычки на указанную дату
    func getProgress(for habitId: UUID, on date: Date) -> HabitProgress?
    
    /// Получает весь прогресс для указанной привычки
    func getAllProgress(for habitId: UUID) -> [HabitProgress]
    
    /// Удаляет весь прогресс для указанной привычки
    func deleteAllProgress(for habitId: UUID)
    
    /// Очищает старый прогресс, старше указанной даты
    func cleanOldProgress(olderThan date: Date)
    
    /// Сохраняет список привычек
    func saveHabits(_ habits: [Habit])
    
    /// Загружает список привычек
    func loadHabits() -> [Habit]
} 