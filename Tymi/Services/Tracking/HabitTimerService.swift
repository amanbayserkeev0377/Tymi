import SwiftUI
import SwiftData
import UIKit.UIApplication

@Observable
final class HabitTimerService: ProgressTrackingService {
    static let shared = HabitTimerService()
    
    // MARK: - Структура данных таймера
    
    private struct TimerData: Codable {
        var accumulatedSeconds: Int  // Накопленное время
        var isActive: Bool           // Активен ли таймер
        var startTime: Date?         // Время запуска (если активен)
    }
    
    // MARK: - Свойства
    
    /// Прогресс для всех таймеров
    private(set) var progressUpdates: [String: Int] = [:]
    
    /// Данные всех таймеров
    private var timerData: [String: TimerData] = [:]
    
    /// Обычный таймер вместо AsyncTimerSequence
    private var timer: Timer?
    
    // MARK: - Инициализация
    
    private init() {
        loadState()
        startTimer()
        setupObservers()
    }
    
    deinit {
        timer?.invalidate()
        saveState()
    }
    
    // MARK: - Настройка таймера
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateActiveTimers()
        }
    }
    
    private func setupObservers() {
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
        saveState()
    }
    
    @objc private func handleForeground() {
        updateActiveTimers()
    }
    
    private func updateActiveTimers() {
        var hasChanges = false
        
        // Обновляем все активные таймеры
        for (habitId, data) in timerData where data.isActive {
            if let startTime = data.startTime {
                let elapsed = Int(Date().timeIntervalSince(startTime))
                let total = data.accumulatedSeconds + elapsed
                
                if progressUpdates[habitId] != total {
                    progressUpdates[habitId] = total
                    hasChanges = true
                }
            }
        }
        
        if hasChanges {
            notifyProgressUpdated()
        }
    }
    
    // MARK: - Управление таймерами
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        // Создаем таймер, если нужно
        if timerData[habitId] == nil {
            timerData[habitId] = TimerData(
                accumulatedSeconds: initialProgress,
                isActive: false,
                startTime: nil
            )
        }
        
        // Если таймер уже запущен - выходим
        guard !(timerData[habitId]?.isActive ?? false) else { return }
        
        // Запускаем таймер
        timerData[habitId]?.startTime = Date()
        timerData[habitId]?.isActive = true
        
        // Обновляем UI
        progressUpdates[habitId] = timerData[habitId]?.accumulatedSeconds ?? 0
        notifyProgressUpdated()
        saveState()
    }
    
    func stopTimer(for habitId: String) {
        guard var data = timerData[habitId], data.isActive else { return }
        
        // Если таймер активен - добавляем прошедшее время
        if let startTime = data.startTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            data.accumulatedSeconds += elapsed
        }
        
        // Останавливаем таймер
        data.startTime = nil
        data.isActive = false
        
        // Обновляем данные
        timerData[habitId] = data
        progressUpdates[habitId] = data.accumulatedSeconds
        
        notifyProgressUpdated()
        saveState()
    }
    
    func resetProgress(for habitId: String) {
        let wasActive = timerData[habitId]?.isActive ?? false
        
        // Сбрасываем таймер
        timerData[habitId] = TimerData(
            accumulatedSeconds: 0,
            isActive: wasActive,
            startTime: wasActive ? Date() : nil
        )
        
        progressUpdates[habitId] = 0
        
        notifyProgressUpdated()
        saveState()
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        // Инициализация, если таймер не существует
        if timerData[habitId] == nil {
            timerData[habitId] = TimerData(
                accumulatedSeconds: 0,
                isActive: false,
                startTime: nil
            )
        }
        
        var data = timerData[habitId]!
        
        // Если таймер активен - добавляем прошедшее время
        if data.isActive, let startTime = data.startTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            data.accumulatedSeconds += elapsed
            data.startTime = Date() // Обновляем время старта
        }
        
        // Добавляем значение
        data.accumulatedSeconds += value
        
        // Обновляем данные
        timerData[habitId] = data
        progressUpdates[habitId] = data.accumulatedSeconds
        
        notifyProgressUpdated()
        saveState()
    }
    
    // MARK: - Получение данных
    
    func getCurrentProgress(for habitId: String) -> Int {
        guard let data = timerData[habitId] else { return 0 }
        
        if data.isActive, let startTime = data.startTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            return data.accumulatedSeconds + elapsed
        }
        
        return data.accumulatedSeconds
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        return timerData[habitId]?.isActive ?? false
    }
    
    // MARK: - Сохранение и загрузка
    
    private func saveState() {
        var dataToSave: [String: TimerData] = [:]
        
        // Сохраняем текущее состояние таймеров
        for (habitId, data) in timerData {
            var timerData = data
            
            // Если таймер активен - обновляем накопленное время
            if data.isActive, let startTime = data.startTime {
                let elapsed = Int(Date().timeIntervalSince(startTime))
                timerData.accumulatedSeconds += elapsed
                timerData.startTime = Date() // Обновляем время старта
            }
            
            dataToSave[habitId] = timerData
        }
        
        // Сохраняем в UserDefaults без Task.detached (упрощение)
        if let encodedData = try? JSONEncoder().encode(dataToSave) {
            UserDefaults.standard.set(encodedData, forKey: "habit.timer.data")
        }
    }
    
    private func loadState() {
        guard let savedData = UserDefaults.standard.data(forKey: "habit.timer.data") else { return }
        
        do {
            let decodedData = try JSONDecoder().decode([String: TimerData].self, from: savedData)
            
            for (habitId, data) in decodedData {
                var timerData = data
                
                // Если таймер был активен - учитываем прошедшее время
                if data.isActive, let startTime = data.startTime {
                    let elapsed = Int(Date().timeIntervalSince(startTime))
                    timerData.accumulatedSeconds += elapsed
                    timerData.startTime = Date() // Обновляем время старта
                }
                
                self.timerData[habitId] = timerData
                progressUpdates[habitId] = timerData.accumulatedSeconds
            }
        } catch {
            print("Ошибка загрузки таймеров: \(error)")
            UserDefaults.standard.removeObject(forKey: "habit.timer.data")
        }
    }
    
    // MARK: - Уведомления
    
    private func notifyProgressUpdated() {
        NotificationCenter.default.post(
            name: .progressUpdated,
            object: self,
            userInfo: ["progressUpdates": progressUpdates]
        )
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
        for (habitId, progress) in progressUpdates where progress > 0 {
            persistCompletions(for: habitId, in: modelContext, date: Date())
        }
    }
    
    // MARK: - Сохраняем упрощенные реализации для интерфейса
    
    var progressUpdatesSequence: AsyncStream<[String: Int]> {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: .progressUpdated,
                object: self,
                queue: .main
            ) { [weak self] notification in
                guard let self = self else {
                    continuation.finish()
                    return
                }
                
                continuation.yield(self.progressUpdates)
            }
            
            continuation.onTermination = { [weak self] _ in
                NotificationCenter.default.removeObserver(observer)
                self?.saveState()
            }
        }
    }
    
    var objectWillChangeSequence: AsyncStream<Void> {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: .progressUpdated,
                object: self,
                queue: .main
            ) { _ in
                continuation.yield(())
            }
            
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
