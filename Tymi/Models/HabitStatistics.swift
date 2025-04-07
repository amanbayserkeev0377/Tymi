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
    
    func saveProgress(_ progress: HabitProgress) {
        let key = progressKey + progress.habitId.uuidString + "_" + formatDate(progress.date)
        if let encoded = try? JSONEncoder().encode(progress) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    func getProgress(for habitId: UUID, on date: Date) -> HabitProgress? {
        let key = progressKey + habitId.uuidString + "_" + formatDate(date)
        guard let data = defaults.data(forKey: key),
              let progress = try? JSONDecoder().decode(HabitProgress.self, from: data)
        else {
            return nil
        }
        return progress
    }
    
    func getAllProgress(for habitId: UUID) -> [HabitProgress] {
        let prefix = progressKey + habitId.uuidString + "_"
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        
        return keys.compactMap { key in
            guard let data = defaults.data(forKey: key),
                  let progress = try? JSONDecoder().decode(HabitProgress.self, from: data)
            else {
                return nil
            }
            return progress
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
} 