import Foundation

class UserDefaultsService: HabitDataStore {
    static let shared = UserDefaultsService()
    private let userDefaults = UserDefaults.standard
    
    private let habitsKey = "habits"
    private let progressKey = "habit_progress"
    private let lastCleanupKey = "last_cleanup_date"
    private let dataVersionKey = "data_version"
    
    private init() {
        migrateIfNeeded()
    }
    
    // MARK: - HabitDataStore Protocol Implementation
    
    func saveProgress(_ progress: HabitProgress) {
        var allProgress = getAllProgress(for: progress.habitId)
        allProgress.append(progress)
        
        if let data = try? JSONEncoder().encode(allProgress) {
            userDefaults.set(data, forKey: "\(progressKey)_\(progress.habitId.uuidString)")
        }
    }
    
    func getProgress(for habitId: UUID, on date: Date) -> HabitProgress? {
        let allProgress = getAllProgress(for: habitId)
        let calendar = Calendar.current
        return allProgress.first { progress in
            calendar.isDate(progress.date, inSameDayAs: date)
        }
    }
    
    func getAllProgress(for habitId: UUID) -> [HabitProgress] {
        guard let data = userDefaults.data(forKey: "\(progressKey)_\(habitId.uuidString)"),
              let progress = try? JSONDecoder().decode([HabitProgress].self, from: data)
        else {
            return []
        }
        return progress.sorted { $0.date < $1.date }
    }
    
    func deleteAllProgress(for habitId: UUID) {
        userDefaults.removeObject(forKey: "\(progressKey)_\(habitId.uuidString)")
    }
    
    func cleanOldProgress(olderThan date: Date) {
        let lastCleanup = userDefaults.object(forKey: lastCleanupKey) as? Date ?? Date.distantPast
        guard date > lastCleanup else { return }
        
        // Получаем все ключи прогресса
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let progressKeys = allKeys.filter { $0.hasPrefix(progressKey) }
        
        for key in progressKeys {
            if let data = userDefaults.data(forKey: key),
               var progress = try? JSONDecoder().decode([HabitProgress].self, from: data) {
                // Фильтруем прогресс, оставляя только записи новее указанной даты
                progress.removeAll { $0.date < date }
                
                if let newData = try? JSONEncoder().encode(progress) {
                    userDefaults.set(newData, forKey: key)
                }
            }
        }
        
        userDefaults.set(date, forKey: lastCleanupKey)
    }
    
    func saveHabits(_ habits: [Habit]) {
        if let data = try? JSONEncoder().encode(habits) {
            userDefaults.set(data, forKey: habitsKey)
        }
    }
    
    func loadHabits() -> [Habit] {
        guard let data = userDefaults.data(forKey: habitsKey),
              let habits = try? JSONDecoder().decode([Habit].self, from: data)
        else {
            return []
        }
        return habits
    }
    
    // MARK: - Migration
    
    private func migrateIfNeeded() {
        let currentVersion = 1
        let savedVersion = userDefaults.integer(forKey: dataVersionKey)
        
        guard savedVersion < currentVersion else { return }
        
        // Миграция с версии 0 на 1
        if savedVersion == 0 {
            migrateFromVersion0()
        }
        
        userDefaults.set(currentVersion, forKey: dataVersionKey)
    }
    
    private func migrateFromVersion0() {
        // Здесь можно добавить логику миграции данных, если она потребуется
    }
} 