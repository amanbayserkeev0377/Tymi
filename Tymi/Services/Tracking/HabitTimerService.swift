import SwiftUI
import SwiftData

@Observable
final class HabitTimerService: ProgressTrackingService {
    static let shared = HabitTimerService()
    
    // MARK: - Properties
    private(set) var progressUpdates: [String: Int] = [:]
    private var activeHabitId: String? = nil
    private var startTime: Date? = nil
    private var timer: Timer?
    
    // MARK: - Initialization
    private init() {
        loadState()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Timer Management
    private func startUITimer() {
        // Останавливаем текущий таймер, если он существует
        timer?.invalidate()
        
        // Запускаем таймер только для обновления UI
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Если нет активного таймера, останавливаем UI-таймер
            if self.activeHabitId == nil {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        
        // Добавляем таймер в общий режим выполнения для более надежной работы
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    // MARK: - ProgressTrackingService Implementation
    func getCurrentProgress(for habitId: String) -> Int {
        // Базовый прогресс (сохраненный)
        let baseProgress = progressUpdates[habitId] ?? 0
        
        // Если этот таймер активен, добавляем прошедшее время с момента старта
        if activeHabitId == habitId, let startTime = startTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            return baseProgress + elapsed
        }
        
        return baseProgress
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        return activeHabitId == habitId
    }
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        // Если таймер уже активен для этой привычки, просто выходим
        if activeHabitId == habitId {
            return
        }
        
        // Если есть другой активный таймер, останавливаем его
        if let activeId = activeHabitId, activeId != habitId {
            stopTimer(for: activeId)
        }
        
        // Устанавливаем активную привычку и время старта
        activeHabitId = habitId
        startTime = Date()
        
        // Инициализируем прогресс, если его нет
        if progressUpdates[habitId] == nil {
            progressUpdates[habitId] = initialProgress
        }
        
        // Запускаем UI-таймер
        if timer == nil {
            startUITimer()
        }
        
        saveState()
    }
    
    func stopTimer(for habitId: String) {
        // Проверяем, что это активный таймер
        guard activeHabitId == habitId, let startTime = startTime else {
            return
        }
        
        // Вычисляем прошедшее время с момента старта
        let elapsed = Int(Date().timeIntervalSince(startTime))
        
        // Добавляем прошедшее время к сохраненному прогрессу
        if elapsed > 0 {
            let currentProgress = progressUpdates[habitId] ?? 0
            progressUpdates[habitId] = currentProgress + elapsed
        }
        
        // Очищаем данные активного таймера
        activeHabitId = nil
        self.startTime = nil
        
        // Останавливаем UI-таймер
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        saveState()
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        // Если таймер активен для этой привычки, сначала останавливаем его
        if activeHabitId == habitId {
            stopTimer(for: habitId)
        }
        
        // Добавляем значение к прогрессу
        let current = progressUpdates[habitId] ?? 0
        progressUpdates[habitId] = max(0, current + value)
        
        saveState()
    }
    
    func resetProgress(for habitId: String) {
        // Останавливаем таймер, если он запущен для этой привычки
        if activeHabitId == habitId {
            activeHabitId = nil
            startTime = nil
            
            // Останавливаем UI-таймер
            if timer != nil {
                timer?.invalidate()
                timer = nil
            }
        }
        
        // Сбрасываем прогресс
        progressUpdates[habitId] = 0
        
        saveState()
    }
    
    // MARK: - Persistence
    private func saveState() {
        if let encodedProgress = try? JSONEncoder().encode(progressUpdates) {
            UserDefaults.standard.set(encodedProgress, forKey: "habit.timer.progress")
        }
        // Не сохраняем информацию о запущенном таймере, так как при выходе из экрана он останавливается
    }
    
    private func loadState() {
        if let savedProgress = UserDefaults.standard.data(forKey: "habit.timer.progress"),
           let decodedProgress = try? JSONDecoder().decode([String: Int].self, from: savedProgress) {
            progressUpdates = decodedProgress
        }
        // Не восстанавливаем активный таймер, так как при выходе из экрана он должен остановиться
    }
}
