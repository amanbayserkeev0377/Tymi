import SwiftUI
import SwiftData
import UIKit.UIApplication

@Observable
final class HabitTimerService: ProgressTrackingService {
    static let shared = HabitTimerService()
    
    // MARK: - Свойства
    
    /// Прогресс для всех таймеров
    private(set) var progressUpdates: [String: Int] = [:]
    
    /// Активные таймеры: habitId -> время старта
    private var activeTimers: [String: Date] = [:]
    
    /// Обычный таймер для обновления UI каждую секунду
    private var timer: Timer?
    
    // MARK: - Инициализация
    
    private init() {
        loadState()
        startTimer()
        setupNotifications()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Настройка таймера и уведомлений
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateActiveTimers()
        }
    }
    
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
        // Останавливаем таймер
        timer?.invalidate()
        
        // Сохраняем текущий прогресс для всех активных таймеров
        pauseAllActiveTimers()
        
        // Сохраняем состояние
        saveState()
    }
    
    @objc private func handleForeground() {
        // Запускаем таймер заново
        startTimer()
        
        // Обновляем состояние активных таймеров
        for habitId in activeTimers.keys {
            activeTimers[habitId] = Date()
        }
        
        // Обновляем UI
        updateActiveTimers()
    }
    
    // MARK: - Обновление таймеров
    
    private func updateActiveTimers() {
        var hasChanges = false
        
        for (habitId, startTime) in activeTimers {
            let accumulated = progressUpdates[habitId] ?? 0
            let elapsed = Int(Date().timeIntervalSince(startTime))
            let total = accumulated + elapsed
            
            if progressUpdates[habitId] != total {
                progressUpdates[habitId] = total
                hasChanges = true
            }
        }
        
        if hasChanges {
            // Уведомляем об изменениях для обновления UI
            NotificationCenter.default.post(
                name: .progressUpdated,
                object: self,
                userInfo: ["progressUpdates": progressUpdates]
            )
        }
    }
    
    private func pauseAllActiveTimers() {
        for (habitId, startTime) in activeTimers {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            progressUpdates[habitId] = (progressUpdates[habitId] ?? 0) + elapsed
        }
    }
    
    // MARK: - Методы управления таймерами
    
    func getCurrentProgress(for habitId: String) -> Int {
        if let startTime = activeTimers[habitId] {
            let accumulated = progressUpdates[habitId] ?? 0
            let elapsed = Int(Date().timeIntervalSince(startTime))
            return accumulated + elapsed
        }
        
        return progressUpdates[habitId] ?? 0
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        return activeTimers[habitId] != nil
    }
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        // Останавливаем другие активные таймеры
        for id in activeTimers.keys where id != habitId {
            stopTimer(for: id)
        }
        
        // Если таймер уже активен, ничего не делаем
        if activeTimers[habitId] != nil {
            return
        }
        
        // Запускаем таймер
        activeTimers[habitId] = Date()
        
        // Инициализируем прогресс, если он не был задан ранее
        if progressUpdates[habitId] == nil {
            progressUpdates[habitId] = initialProgress
        }
        
        // Уведомляем об изменениях для обновления UI
        NotificationCenter.default.post(
            name: .progressUpdated,
            object: self,
            userInfo: ["progressUpdates": progressUpdates]
        )
        
        saveState()
    }
    
    func stopTimer(for habitId: String) {
        guard let startTime = activeTimers[habitId] else { return }
        
        // Добавляем прошедшее время к накопленному
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let accumulated = progressUpdates[habitId] ?? 0
        progressUpdates[habitId] = accumulated + elapsed
        
        // Удаляем таймер из активных
        activeTimers.removeValue(forKey: habitId)
        
        // Уведомляем об изменениях для обновления UI
        NotificationCenter.default.post(
            name: .progressUpdated,
            object: self,
            userInfo: ["progressUpdates": progressUpdates]
        )
        
        saveState()
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        // Если таймер активен, сначала останавливаем его
        if activeTimers[habitId] != nil {
            stopTimer(for: habitId)
        }
        
        // Добавляем значение к прогрессу
        let current = progressUpdates[habitId] ?? 0
        progressUpdates[habitId] = max(0, current + value)
        
        // Уведомляем об изменениях для обновления UI
        NotificationCenter.default.post(
            name: .progressUpdated,
            object: self,
            userInfo: ["progressUpdates": progressUpdates]
        )
        
        saveState()
    }
    
    func resetProgress(for habitId: String) {
        // Останавливаем таймер, если он запущен
        if activeTimers[habitId] != nil {
            activeTimers[habitId] = Date()
        }
        
        // Сбрасываем прогресс
        progressUpdates[habitId] = 0
        
        // Уведомляем об изменениях для обновления UI
        NotificationCenter.default.post(
            name: .progressUpdated,
            object: self,
            userInfo: ["progressUpdates": progressUpdates]
        )
        
        saveState()
    }
    
    // MARK: - Сохранение и загрузка
    
    private func saveState() {
        // Сохраняем данные активных таймеров
        let activeTimersData: [String: TimeInterval] = activeTimers.mapValues { date in
            date.timeIntervalSince1970
        }
        
        if let encodedTimers = try? JSONEncoder().encode(activeTimersData),
           let encodedProgress = try? JSONEncoder().encode(progressUpdates) {
            UserDefaults.standard.set(encodedTimers, forKey: "habit.timer.active")
            UserDefaults.standard.set(encodedProgress, forKey: "habit.timer.progress")
        }
    }
    
    private func loadState() {
        // Загружаем данные прогресса
        if let savedProgress = UserDefaults.standard.data(forKey: "habit.timer.progress"),
           let decodedProgress = try? JSONDecoder().decode([String: Int].self, from: savedProgress) {
            progressUpdates = decodedProgress
        }
        
        // Загружаем данные активных таймеров
        if let savedTimers = UserDefaults.standard.data(forKey: "habit.timer.active"),
           let decodedTimers = try? JSONDecoder().decode([String: TimeInterval].self, from: savedTimers) {
            
            let now = Date()
            activeTimers = decodedTimers.compactMapValues { timeInterval in
                let date = Date(timeIntervalSince1970: timeInterval)
                
                // Если таймер был активен больше 24 часов назад, считаем ошибкой и не восстанавливаем
                if now.timeIntervalSince(date) > 24*60*60 {
                    return nil
                }
                
                // Добавляем прошедшее время к накопленному и обновляем стартовую дату
                let elapsed = Int(now.timeIntervalSince(date))
                let habitId = decodedTimers.first(where: { $0.value == timeInterval })?.key ?? ""
                if !habitId.isEmpty {
                    progressUpdates[habitId] = (progressUpdates[habitId] ?? 0) + elapsed
                }
                
                // Возвращаем текущую дату как новую стартовую точку
                return now
            }
        }
    }
    
    // MARK: - SwiftData интеграция
    
    func persistCompletions(for habitId: String, in modelContext: ModelContext, date: Date = .now) {
        let currentProgress = getCurrentProgress(for: habitId)
        
        guard currentProgress > 0 else { return }
        
        do {
            // Находим привычку по UUID
            guard let uuid = UUID(uuidString: habitId) else { return }
            
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.uuid == uuid })
            let habits = try modelContext.fetch(descriptor)
            
            guard let habit = habits.first else { return }
            
            let existingProgress = habit.progressForDate(date)
            
            // Если прогресс не изменился - выходим
            if currentProgress == existingProgress { return }
            
            // Удаляем все старые записи за этот день
            let oldCompletions = habit.completions.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }
            
            for completion in oldCompletions {
                modelContext.delete(completion)
            }
            
            // Добавляем новую запись
            if currentProgress > 0 {
                let newCompletion = HabitCompletion(date: date, value: currentProgress, habit: habit)
                habit.completions.append(newCompletion)
            }
            
            try modelContext.save()
        } catch {
            print("Ошибка сохранения прогресса: \(error)")
        }
    }
    
    func persistAllCompletionsToSwiftData(modelContext: ModelContext) {
        // Сохраняем все таймеры с ненулевым прогрессом
        for (habitId, _) in progressUpdates {
            persistCompletions(for: habitId, in: modelContext, date: Date())
        }
    }
}
