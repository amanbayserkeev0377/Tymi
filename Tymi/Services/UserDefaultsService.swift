import Foundation

class UserDefaultsService {
    private static let habitsKey = "savedHabits"
    private static let progressKey = "habit_progress_"
    private static let versionKey = "habitStoreVersion"
    private static let currentVersion = 1
    
    private let defaults = UserDefaults.standard
    
    init() {
        migrateIfNeeded()
    }
    
    func saveHabits(_ habits: [Habit]) {
        do {
            let data = try JSONEncoder().encode(habits)
            defaults.set(data, forKey: Self.habitsKey)
        } catch {
            print("Error saving habits: \(error)")
        }
    }
    
    func loadHabits() -> [Habit] {
        guard let data = defaults.data(forKey: Self.habitsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([Habit].self, from: data)
        } catch {
            print("Error loading habits: \(error)")
            return []
        }
    }
    
    func saveProgress(_ progress: HabitProgress) {
        let key = Self.progressKey + progress.habitId.uuidString + "_" + formatDate(progress.date)
        do {
            let data = try JSONEncoder().encode(progress)
            defaults.set(data, forKey: key)
        } catch {
            print("Error saving progress: \(error)")
        }
    }
    
    func getProgress(for habitId: UUID, on date: Date) -> HabitProgress? {
        let key = Self.progressKey + habitId.uuidString + "_" + formatDate(date)
        guard let data = defaults.data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(HabitProgress.self, from: data)
        } catch {
            print("Error loading progress: \(error)")
            return nil
        }
    }
    
    func getAllProgress(for habitId: UUID) -> [HabitProgress] {
        let prefix = Self.progressKey + habitId.uuidString + "_"
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
    
    func cleanOldProgress(olderThan date: Date) {
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(Self.progressKey) }
        
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
        let version = defaults.integer(forKey: Self.versionKey)
        if version == 0 || version < Self.currentVersion {
            defaults.set(Self.currentVersion, forKey: Self.versionKey)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
} 