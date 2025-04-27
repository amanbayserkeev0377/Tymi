import Foundation
import Combine

class HabitTimerService: ObservableObject {
    static let shared = HabitTimerService()
    
    @Published private var timers: [String: Timer] = [:]
    @Published private var progress: [String: Int] = [:]
    @Published private var wasRunning: [String: Bool] = [:]
    
    private init() {}
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        // Останавливаем существующий таймер, если он есть
        stopTimer(for: habitId)
        
        // Устанавливаем начальный прогресс
        progress[habitId] = initialProgress
        
        // Создаем новый таймер
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.progress[habitId] = (self?.progress[habitId] ?? 0) + 1
        }
        timers[habitId] = timer
        wasRunning[habitId] = true
    }
    
    func stopTimer(for habitId: String) {
        timers[habitId]?.invalidate()
        timers[habitId] = nil
        wasRunning[habitId] = false
    }
    
    func resetTimer(for habitId: String) {
        // Останавливаем таймер перед сбросом прогресса
        stopTimer(for: habitId)
        progress[habitId] = 0
        wasRunning[habitId] = false
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        // Останавливаем таймер перед изменением прогресса
        stopTimer(for: habitId)
        progress[habitId] = (progress[habitId] ?? 0) + value
        wasRunning[habitId] = false
    }
    
    func getCurrentProgress(for habitId: String) -> Int {
        return progress[habitId] ?? 0
    }
    
    func getTotalProgress(for habitId: String) -> Int {
        return progress[habitId] ?? 0
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        return timers[habitId] != nil
    }
    
    func wasTimerRunning(for habitId: String) -> Bool {
        return wasRunning[habitId] ?? false
    }
    
    func restoreTimerState(for habitId: String) {
        if wasRunning[habitId] ?? false {
            startTimer(for: habitId, initialProgress: progress[habitId] ?? 0)
        }
    }
} 