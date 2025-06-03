import SwiftUI
import SwiftData

@Observable
final class HabitCounterService: ProgressTrackingService {
    static let shared = HabitCounterService()
    
    // MARK: - Properties
    
    /// Прогресс для всех счетчиков
    private(set) var progressUpdates: [String: Int] = [:]
    
    // MARK: - Initialization
    
    private init() {
        loadState()
    }
    
    // MARK: - ProgressTrackingService Implementation
    
    func getCurrentProgress(for habitId: String) -> Int {
        return progressUpdates[habitId] ?? 0
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        let currentValue = progressUpdates[habitId] ?? 0
        let newValue = max(0, currentValue + value)
        
        if currentValue != newValue {
            progressUpdates[habitId] = newValue
            saveState()
        }
    }
    
    func resetProgress(for habitId: String) {
        if progressUpdates[habitId] != nil && progressUpdates[habitId] != 0 {
            progressUpdates[habitId] = 0
            saveState()
        }
    }
    
    // MARK: - Methods for Timers (stubs - not used for counters)
    
    func isTimerRunning(for habitId: String) -> Bool { return false }
    func startTimer(for habitId: String, initialProgress: Int = 0) { }
    func stopTimer(for habitId: String) { }
    
    // MARK: - Saving and Loading
    
    private func saveState() {
        if let encodedData = try? JSONEncoder().encode(progressUpdates) {
            UserDefaults.standard.set(encodedData, forKey: "habit.counter.data")
        }
    }
    
    private func loadState() {
        if let savedData = UserDefaults.standard.data(forKey: "habit.counter.data"),
           let decodedData = try? JSONDecoder().decode([String: Int].self, from: savedData) {
            progressUpdates = decodedData
        }
    }
}
