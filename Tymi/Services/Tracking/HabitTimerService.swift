import SwiftUI
import SwiftData

@Observable
final class HabitTimerService: ProgressTrackingService {
    static let shared = HabitTimerService()
    
    // MARK: - Properties
    private(set) var progressUpdates: [String: Int] = [:]
    private var startTimes: [String: Date] = [:]
    private var timer: Timer?
    
    // MARK: - Initialization
    private init() {
        loadState()
        setupNotifications()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Lifecycle Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleBackground() {
        // Когда приложение уходит в фон, останавливаем таймер, но НЕ останавливаем подсчет времени
        timer?.invalidate()
        timer = nil
        saveState()
    }
    
    @objc private func handleForeground() {
        // Когда приложение возвращается из фона, запускаем таймер для UI-обновлений
        if !startTimes.isEmpty {
            startGlobalTimer()
        }
    }
    
    // MARK: - Timer Management
    private func startGlobalTimer() {
        // Останавливаем текущий таймер, если он существует
        timer?.invalidate()
        
        // Запускаем таймер только для обновления UI
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Если нет активных таймеров, останавливаем глобальный таймер
            if self.startTimes.isEmpty {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        
        // Добавляем таймер в общий режим выполнения для более надежной работы
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    // MARK: - ProgressTrackingService Implementation
    func getCurrentProgress(for habitId: String) -> Int {
        // Базовый прогресс (сохраненный)
        let baseProgress = progressUpdates[habitId] ?? 0
        
        // Если таймер активен, добавляем прошедшее время с момента старта
        if let startTime = startTimes[habitId] {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            return baseProgress + elapsed
        }
        
        return baseProgress
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        return startTimes[habitId] != nil
    }
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        // Останавливаем другие активные таймеры
        for id in startTimes.keys where id != habitId {
            stopTimer(for: id)
        }
        
        // Если таймер уже активен, просто выходим
        if startTimes[habitId] != nil {
            return
        }
        
        // Запоминаем время старта
        startTimes[habitId] = Date()
        
        // Инициализируем прогресс, если его нет
        if progressUpdates[habitId] == nil {
            progressUpdates[habitId] = initialProgress
        }
        
        // Запускаем глобальный таймер для UI-обновлений
        if timer == nil {
            startGlobalTimer()
        }
        
        saveState()
    }
    
    func stopTimer(for habitId: String) {
        guard let startTime = startTimes[habitId] else { return }
        
        // Вычисляем прошедшее время с момента старта
        let elapsed = Int(Date().timeIntervalSince(startTime))
        
        // Добавляем прошедшее время к сохраненному прогрессу
        if elapsed > 0 {
            let currentProgress = progressUpdates[habitId] ?? 0
            progressUpdates[habitId] = currentProgress + elapsed
        }
        
        // Удаляем время старта
        startTimes.removeValue(forKey: habitId)
        
        // Если нет активных таймеров, останавливаем глобальный таймер
        if startTimes.isEmpty && timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        saveState()
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        // Если таймер активен, сначала останавливаем его
        if startTimes[habitId] != nil {
            stopTimer(for: habitId)
        }
        
        // Добавляем значение к прогрессу
        let current = progressUpdates[habitId] ?? 0
        progressUpdates[habitId] = max(0, current + value)
        
        saveState()
    }
    
    func resetProgress(for habitId: String) {
        // Останавливаем таймер, если он запущен
        if startTimes[habitId] != nil {
            startTimes.removeValue(forKey: habitId)
            
            // Если нет активных таймеров, останавливаем глобальный таймер
            if startTimes.isEmpty && timer != nil {
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
        let startTimesData: [String: TimeInterval] = startTimes.mapValues { $0.timeIntervalSince1970 }
        
        if let encodedTimes = try? JSONEncoder().encode(startTimesData),
           let encodedProgress = try? JSONEncoder().encode(progressUpdates) {
            UserDefaults.standard.set(encodedTimes, forKey: "habit.timer.active")
            UserDefaults.standard.set(encodedProgress, forKey: "habit.timer.progress")
        }
    }
    
    private func loadState() {
        if let savedProgress = UserDefaults.standard.data(forKey: "habit.timer.progress"),
           let decodedProgress = try? JSONDecoder().decode([String: Int].self, from: savedProgress) {
            progressUpdates = decodedProgress
        }
        
        if let savedTimes = UserDefaults.standard.data(forKey: "habit.timer.active"),
           let decodedTimes = try? JSONDecoder().decode([String: TimeInterval].self, from: savedTimes) {
            
            let now = Date()
            
            for (habitId, timeInterval) in decodedTimes {
                let startTime = Date(timeIntervalSince1970: timeInterval)
                
                // Если таймер был запущен больше 24 часов назад, считаем ошибкой и не восстанавливаем
                if now.timeIntervalSince(startTime) > 24*60*60 {
                    continue
                }
                
                // Добавляем прошедшее время к накопленному и останавливаем таймер
                let elapsed = Int(now.timeIntervalSince(startTime))
                if elapsed > 0 {
                    let currentProgress = progressUpdates[habitId] ?? 0
                    progressUpdates[habitId] = currentProgress + elapsed
                }
                
                // Запускаем таймер заново с текущим временем
                startTimes[habitId] = now
            }
            
            // Запускаем глобальный таймер для UI-обновлений, если есть активные таймеры
            if !startTimes.isEmpty {
                startGlobalTimer()
            }
        }
    }
}
