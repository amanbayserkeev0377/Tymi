import Foundation

struct HabitProgress: Codable {
    let habitId: UUID
    let date: Date
    let value: Double
    let isCompleted: Bool
}

struct HabitStatistics {
    private let defaults = UserDefaults.standard
    private let progressKey = "habit_progress_"
    private let versionKey = "habitStatisticsVersion"
    private let currentVersion = 1
    
    enum StatisticsError: Error {
        case encodingFailed
        case decodingFailed
        case invalidVersion
    }
    
    init() {
        migrateIfNeeded()
    }
    
    func saveProgress(_ progress: HabitProgress) {
        let key = progressKey + progress.habitId.uuidString + "_" + formatDate(progress.date)
        do {
            let encoded = try JSONEncoder().encode(progress)
            defaults.set(encoded, forKey: key)
        } catch {
            print("Error saving progress: \(error)")
            // В будущем здесь можно добавить обработку ошибок через UI
        }
    }
    
    func getProgress(for habitId: UUID, on date: Date) -> HabitProgress? {
        let key = progressKey + habitId.uuidString + "_" + formatDate(date)
        guard let data = defaults.data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(HabitProgress.self, from: data)
        } catch {
            print("Error loading progress: \(error)")
            return nil
        }
    }
    
    func getAllProgress(for habitId: UUID) -> [HabitProgress] {
        let prefix = progressKey + habitId.uuidString + "_"
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        
        return keys.compactMap { key in
            guard let data = defaults.data(forKey: key) else { return nil }
            
            do {
                return try JSONDecoder().decode(HabitProgress.self, from: data)
            } catch {
                print("Error loading progress for key \(key): \(error)")
                return nil
            }
        }
    }
    
    func deleteAllProgress(for habitId: UUID) {
        let prefix = progressKey + habitId.uuidString + "_"
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        
        for key in keys {
            defaults.removeObject(forKey: key)
        }
    }
    
    func cleanOldProgress(olderThan date: Date) {
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(progressKey) }
        
        for key in keys {
            guard let data = defaults.data(forKey: key),
                  let progress = try? JSONDecoder().decode(HabitProgress.self, from: data)
            else { continue }
            
            if progress.date < date {
                defaults.removeObject(forKey: key)
            }
        }
    }
    
    private func migrateIfNeeded() {
        let version = defaults.integer(forKey: versionKey)
        
        // Если версия 0 (нет версии) или отличается от текущей
        if version == 0 || version < currentVersion {
            // В будущем здесь будет миграция данных
            defaults.set(currentVersion, forKey: versionKey)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
