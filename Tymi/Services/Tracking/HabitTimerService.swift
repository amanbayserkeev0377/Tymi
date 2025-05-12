import SwiftUI
import SwiftData
import UIKit.UIApplication

@Observable
final class HabitTimerService: ProgressTrackingService {
    static let shared = HabitTimerService()
    
    // MARK: - Properties
    
    /// Прогресс для всех таймеров
    private(set) var progressUpdates: [String: Int] = [:]
    
    /// Активные таймеры: habitId -> время старта
    private var activeTimers: [String: Date] = [:]
    
    /// Задачи таймеров для каждой привычки
    private var timerTasks: [String: Task<Void, Never>] = [:]
    
    // MARK: - Initialization
    
    private init() {
        loadState()
        setupNotifications()
    }
    
    deinit {
        // Отменяем все таймерные задачи
        for (_, task) in timerTasks {
            task.cancel()
        }
    }
    
    // MARK: - Настройка уведомлений о жизненном цикле приложения
    
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
        // При уходе в фон останавливаем все задачи и сохраняем прогресс
        pauseAllActiveTimers()
        saveState()
    }
    
    @objc private func handleForeground() {
        let now = Date()
        for habitId in activeTimers.keys {
            if let startTime = activeTimers[habitId] {
                let elapsed = Int(now.timeIntervalSince(startTime))
                progressUpdates[habitId] = (progressUpdates[habitId] ?? 0) + elapsed
            }
            activeTimers[habitId] = now
            startTimerTask(for: habitId)
        }
    }
    
    // MARK: - Timer Tasks Management
    
    private func startTimerTask(for habitId: String) {
        // Отменяем существующую задачу, если она есть
        timerTasks[habitId]?.cancel()
        
        // Создаем новую задачу для этого таймера
        timerTasks[habitId] = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // Начальное время и прогресс
                let startTime = self.activeTimers[habitId] ?? Date()
                let initialProgress = self.progressUpdates[habitId] ?? 0
                
                // Для точного отслеживания обновлений
                var lastElapsed = 0
                
                while !Task.isCancelled && self.activeTimers[habitId] != nil {
                    // Проверяем текущее время
                    let now = Date()
                    let totalElapsed = Int(now.timeIntervalSince(startTime))
                    
                    // Обновляем только когда elapsed изменился
                    if totalElapsed > lastElapsed {
                        // Обновляем на главном потоке
                        await MainActor.run {
                            self.progressUpdates[habitId] = initialProgress + totalElapsed
                        }
                        lastElapsed = totalElapsed
                    }
                    
                    // Ждем короткое время для следующей проверки
                    // Используем более короткий интервал, чтобы не пропустить изменение секунды
                    try await Task.sleep(for: .milliseconds(50))
                }
            } catch {
                // Задача отменена или произошла ошибка
                print("Timer task cancelled or error: \(error)")
            }
        }
    }
    
    private func pauseAllActiveTimers() {
        // Отменяем все задачи таймеров
        for (habitId, task) in timerTasks {
            task.cancel()
            
            // Если таймер был активен, сохраняем его текущее значение
            if let startTime = activeTimers[habitId] {
                let now = Date()
                let elapsed = Int(now.timeIntervalSince(startTime))
                progressUpdates[habitId] = (progressUpdates[habitId] ?? 0) + elapsed
            }
        }
        
        // Очищаем задачи
        timerTasks.removeAll()
    }
    
    // MARK: - ProgressTrackingService Implementation
    
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
        
        // Если таймер уже активен, просто выходим
        if activeTimers[habitId] != nil {
            return
        }
        
        // Запускаем таймер
        activeTimers[habitId] = Date()
        
        // Инициализируем прогресс, если он не был задан ранее
        if progressUpdates[habitId] == nil {
            progressUpdates[habitId] = initialProgress
        }
        
        // Запускаем задачу таймера
        startTimerTask(for: habitId)
        
        saveState()
    }
    
    func stopTimer(for habitId: String) {
        guard let startTime = activeTimers[habitId] else { return }
        
        // Отменяем задачу таймера
        timerTasks[habitId]?.cancel()
        timerTasks.removeValue(forKey: habitId)
        
        // Добавляем прошедшее время к накопленному
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let accumulated = progressUpdates[habitId] ?? 0
        progressUpdates[habitId] = accumulated + elapsed
        
        // Удаляем таймер из активных
        activeTimers.removeValue(forKey: habitId)
        
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
        
        saveState()
    }
    
    func resetProgress(for habitId: String) {
        // Останавливаем таймер, если он запущен
        if activeTimers[habitId] != nil {
            // Отменяем текущую задачу
            timerTasks[habitId]?.cancel()
            
            // Сбрасываем время старта
            activeTimers[habitId] = Date()
            
            // Запускаем новую задачу
            startTimerTask(for: habitId)
        }
        
        // Сбрасываем прогресс
        progressUpdates[habitId] = 0
        
        saveState()
    }
    
    // MARK: - Сохранение и загрузка (без изменений)
    
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
            
            // Запускаем задачи для активных таймеров
            for habitId in activeTimers.keys {
                startTimerTask(for: habitId)
            }
        }
    }
    
    // MARK: - SwiftData Integration
    
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
