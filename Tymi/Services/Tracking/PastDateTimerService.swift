import SwiftUI
import SwiftData

@Observable
final class PastDateTimerService: ProgressTrackingService {
    // MARK: - Properties
    private(set) var progressUpdates: [String: Int] = [:]
    private var startTimes: [String: Date] = [:]
    private var timer: Timer?
    private var onUpdateCallback: (() -> Void)?
    
    // MARK: - Initialization
    init(initialProgress: Int, habitId: String, onUpdate: @escaping () -> Void) {
        self.progressUpdates[habitId] = initialProgress
        self.onUpdateCallback = onUpdate
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        onUpdateCallback = nil
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
        
        // Запускаем локальный таймер для UI-обновлений
        if timer == nil {
            startLocalTimer()
        }
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
        
        // Если нет активных таймеров, останавливаем локальный таймер
        if startTimes.isEmpty && timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        // Вызываем callback для обновления UI
        onUpdateCallback?()
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        // Если таймер активен, сначала останавливаем его
        if startTimes[habitId] != nil {
            stopTimer(for: habitId)
        }
        
        // Добавляем значение к прогрессу
        let current = progressUpdates[habitId] ?? 0
        progressUpdates[habitId] = max(0, current + value)
        
        // Вызываем callback для обновления UI
        onUpdateCallback?()
    }
    
    func resetProgress(for habitId: String) {
        // Останавливаем таймер, если он запущен
        if startTimes[habitId] != nil {
            startTimes.removeValue(forKey: habitId)
            
            // Если нет активных таймеров, останавливаем локальный таймер
            if startTimes.isEmpty && timer != nil {
                timer?.invalidate()
                timer = nil
            }
        }
        
        // Сбрасываем прогресс
        progressUpdates[habitId] = 0
        
        // Вызываем callback для обновления UI
        onUpdateCallback?()
    }
    
    // MARK: - Additional Methods
    private func startLocalTimer() {
        // Останавливаем текущий таймер, если он существует
        timer?.invalidate()
        timer = nil
        
        // Запускаем таймер для обновления UI каждые 0.5 секунды
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Вызываем callback для обновления UI
            self.onUpdateCallback?()
            
            // Если нет активных таймеров, останавливаем локальный таймер
            if self.startTimes.isEmpty {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        
        // Добавляем таймер в общий режим выполнения для более надежной работы
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    // MARK: - Public Methods для управления состоянием
    
    /// Принудительно останавливает все активные таймеры
    func stopAllTimers() {
        let activeHabits = Array(startTimes.keys)
        for habitId in activeHabits {
            stopTimer(for: habitId)
        }
    }
    
    /// Проверяет, есть ли активные таймеры
    var hasActiveTimers: Bool {
        return !startTimes.isEmpty
    }
    
    // Заглушки для требуемых методов протокола
    func persistCompletions(for habitId: String, in modelContext: ModelContext, date: Date) {
        // Пустая реализация - мы не сохраняем прогресс в базу из этого сервиса
    }
    
    func persistAllCompletionsToSwiftData(modelContext: ModelContext) {
        // Пустая реализация - мы не сохраняем прогресс в базу из этого сервиса
    }
}
