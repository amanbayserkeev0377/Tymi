import Foundation
import Combine
import SwiftData

class HabitTimerService: ObservableObject {
    static let shared = HabitTimerService()
    
    // MARK: - Properties
    
    // Модель данных для таймеров
    private struct TimerData {
        var startTime: Date?           // Время запуска таймера (nil если не запущен)
        var accumulatedSeconds: Int    // Накопленное время в секундах
        var isActive: Bool             // Флаг активности таймера
    }
    
    // Словарь с данными таймеров
    private var habitTimers: [String: TimerData] = [:]
    private let lock = NSLock()
    private var masterTimer: Timer?
    private let updateInterval: TimeInterval = 1.0
    
    // Публикуемое значение прогресса
    @Published private(set) var progressUpdates: [String: Int] = [:]
    
    // UserDefaults ключи
    private enum Keys {
        static let timerData = "habit.timer.data"
        static let backgroundTime = "habit.background.time"
        static let activeTimers = "habit.active.timers"
    }
    
    // MARK: - Инициализация
    
    private init() {
        loadSavedState()
        setupMasterTimer()
    }
    
    deinit {
        masterTimer?.invalidate()
    }
    
    // MARK: - Настройка таймеров
    
    private func setupMasterTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.masterTimer = Timer.scheduledTimer(
                withTimeInterval: self.updateInterval,
                repeats: true
            ) { [weak self] _ in
                self?.updateAllProgress()
            }
            
            if let timer = self.masterTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }
    
    private func updateAllProgress() {
        var updatedProgress: [String: Int] = [:]
        var hasChanges = false
        
        lock.lock()
        let now = Date()
        for (habitId, data) in habitTimers where data.isActive {
            if let startTime = data.startTime {
                let elapsedTime = Int(now.timeIntervalSince(startTime))
                let totalSeconds = data.accumulatedSeconds + elapsedTime
                
                if progressUpdates[habitId] != totalSeconds {
                    updatedProgress[habitId] = totalSeconds
                    hasChanges = true
                }
            }
        }
        lock.unlock()
        
        if hasChanges {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                for (habitId, progress) in updatedProgress {
                    self.progressUpdates[habitId] = progress
                }
                
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Сохранение и загрузка состояния
    
    private func loadSavedState() {
        // Загружаем накопленное время
        if let savedData = UserDefaults.standard.dictionary(forKey: Keys.timerData) as? [String: Int] {
            lock.lock()
            for (habitId, seconds) in savedData {
                habitTimers[habitId] = TimerData(
                    startTime: nil,
                    accumulatedSeconds: seconds,
                    isActive: false
                )
                progressUpdates[habitId] = seconds
            }
            lock.unlock()
        }
        
        // Восстанавливаем активные таймеры
        if let activeIds = UserDefaults.standard.stringArray(forKey: Keys.activeTimers) {
            for habitId in activeIds {
                startTimer(for: habitId)
            }
        }
    }
    
    private func saveState() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            var dataToSave: [String: Int] = [:]
            var activeTimers: [String] = []
            
            self.lock.lock()
            for (habitId, data) in self.habitTimers {
                dataToSave[habitId] = data.accumulatedSeconds
                if data.isActive {
                    activeTimers.append(habitId)
                }
            }
            self.lock.unlock()
            
            UserDefaults.standard.set(dataToSave, forKey: HabitTimerService.Keys.timerData)
            UserDefaults.standard.set(activeTimers, forKey: HabitTimerService.Keys.activeTimers)
        }
    }
    
    // MARK: - Обработка состояния приложения
    
    func handleAppDidEnterBackground() {
        // Сохраняем время ухода в фон
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Keys.backgroundTime)
        
        lock.lock()
        // Обновляем накопленное время для всех активных таймеров
        for (habitId, data) in habitTimers where data.isActive {
            if let startTime = data.startTime {
                let elapsedTime = Int(Date().timeIntervalSince(startTime))
                habitTimers[habitId]?.accumulatedSeconds += elapsedTime
                
                // Обновляем время начала отсчета, НО оставляем таймер активным
                habitTimers[habitId]?.startTime = Date()
            }
        }
        lock.unlock()
        
        saveState()
    }
    
    func handleAppWillEnterForeground() {
        guard let timestamp = UserDefaults.standard.object(forKey: Keys.backgroundTime) as? Double else {
            return
        }
        
        let backgroundDate = Date(timeIntervalSince1970: timestamp)
        let timeInBackground = Int(Date().timeIntervalSince(backgroundDate))
        
        guard timeInBackground > 0 else { return }
        
        lock.lock()
        let now = Date()
        // Получаем список активных таймеров
        let activeTimerIds = habitTimers.filter { $0.value.isActive }.keys
        
        // Для всех активных таймеров добавляем время, проведенное в фоне
        for habitId in activeTimerIds {
            habitTimers[habitId]?.accumulatedSeconds += timeInBackground
            habitTimers[habitId]?.startTime = now
            progressUpdates[habitId] = habitTimers[habitId]?.accumulatedSeconds ?? 0
        }
        lock.unlock()
        
        // Уведомляем слушателей об изменениях
        if !activeTimerIds.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
        
        saveState()
    }
    
    // MARK: - Управление таймерами
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        lock.lock()
        
        // Создаем запись для привычки, если нет
        if habitTimers[habitId] == nil {
            habitTimers[habitId] = TimerData(
                startTime: nil,
                accumulatedSeconds: initialProgress,
                isActive: false
            )
        }
        
        // Если таймер уже активен, не делаем ничего
        guard !(habitTimers[habitId]?.isActive ?? false) else {
            lock.unlock()
            return
        }
        
        // Активируем таймер
        let now = Date()
        habitTimers[habitId]?.startTime = now
        habitTimers[habitId]?.isActive = true
        
        // Фиксируем текущий прогресс для уведомления UI
        let progress = habitTimers[habitId]?.accumulatedSeconds ?? 0
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressUpdates[habitId] = progress
            self.objectWillChange.send()
        }
        
        saveState()
    }
    
    func stopTimer(for habitId: String) {
        lock.lock()
        
        // Проверяем, что таймер существует и активен
        guard var data = habitTimers[habitId], data.isActive else {
            lock.unlock()
            return
        }
        
        // Обновляем накопленное время
        if let startTime = data.startTime {
            let elapsedTime = Int(Date().timeIntervalSince(startTime))
            data.accumulatedSeconds += elapsedTime
        }
        
        // Деактивируем таймер
        data.startTime = nil
        data.isActive = false
        
        // Обновляем состояние
        habitTimers[habitId] = data
        let finalProgress = data.accumulatedSeconds
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressUpdates[habitId] = finalProgress
            self.objectWillChange.send()
        }
        
        saveState()
    }
    
    func resetTimer(for habitId: String) {
        lock.lock()
        
        // Проверяем, активен ли таймер
        let wasActive = habitTimers[habitId]?.isActive ?? false
        
        // Сбрасываем данные
        habitTimers[habitId] = TimerData(
            startTime: wasActive ? Date() : nil,
            accumulatedSeconds: 0,
            isActive: wasActive
        )
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressUpdates[habitId] = 0
            self.objectWillChange.send()
        }
        
        saveState()
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        lock.lock()
        
        // Проверяем, существует ли запись
        if habitTimers[habitId] == nil {
            habitTimers[habitId] = TimerData(
                startTime: nil,
                accumulatedSeconds: 0,
                isActive: false
            )
        }
        
        // Сохраняем состояние активности
        let wasActive = habitTimers[habitId]?.isActive ?? false
        var currentSeconds = habitTimers[habitId]?.accumulatedSeconds ?? 0
        
        // Если таймер активен, добавляем накопленное время
        if wasActive, let startTime = habitTimers[habitId]?.startTime {
            let elapsedTime = Int(Date().timeIntervalSince(startTime))
            currentSeconds += elapsedTime
        }
        
        // Добавляем новое значение
        currentSeconds += value
        
        // Обновляем состояние
        habitTimers[habitId]?.accumulatedSeconds = currentSeconds
        
        // Если таймер был активен, обновляем время начала
        if wasActive {
            habitTimers[habitId]?.startTime = Date()
        }
        
        // Фиксируем текущий прогресс для уведомления UI
        let finalProgress = currentSeconds
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressUpdates[habitId] = finalProgress
            self.objectWillChange.send()
        }
        
        saveState()
    }
    
    // MARK: - Получение данных
    
    func getCurrentProgress(for habitId: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        // Если таймер активен, добавляем текущее накопленное время
        if let data = habitTimers[habitId], data.isActive, let startTime = data.startTime {
            let elapsedTime = Int(Date().timeIntervalSince(startTime))
            return data.accumulatedSeconds + elapsedTime
        }
        
        return habitTimers[habitId]?.accumulatedSeconds ?? 0
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return habitTimers[habitId]?.isActive ?? false
    }
    
    // MARK: - SwiftData интеграция
    
    func persistCompletions(for habitId: String, in modelContext: ModelContext, date: Date = .now) {
        let currentProgress = getCurrentProgress(for: habitId)
        
        guard currentProgress > 0 else { return }
        
        DispatchQueue.main.async {
            // Находим привычку по ID
            let descriptor = FetchDescriptor<Habit>()
            do {
                let habits = try modelContext.fetch(descriptor)
                guard let habit = habits.first(where: { String(describing: $0.persistentModelID) == habitId }) else {
                    return
                }
                
                // Получаем существующий прогресс
                let existingProgress = habit.progressForDate(date)
                
                // Добавляем новый прогресс, если он отличается
                if currentProgress != existingProgress {
                    habit.addProgress(currentProgress - existingProgress, for: date)
                    try modelContext.save()
                }
            } catch {
                print("Error saving progress: \(error)")
            }
        }
    }
    
    // MARK: - Дополнительные методы
    
    // Метод для ограничения количества одновременных таймеров
    private func isMaxTimersLimitReached() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let activeCount = habitTimers.values.filter { $0.isActive }.count
        return activeCount >= 3 // Ограничение в 3 активных таймера
    }
    
    // Метод для очистки неиспользуемых таймеров
    func cleanupUnusedTimers() {
        lock.lock()
        
        // Находим неактивные таймеры с нулевым прогрессом
        let unusedIds = habitTimers.filter {
            !$0.value.isActive && $0.value.accumulatedSeconds == 0
        }.keys
        
        // Удаляем их из словаря
        for id in unusedIds {
            habitTimers.removeValue(forKey: id)
            progressUpdates.removeValue(forKey: id)
        }
        
        lock.unlock()
        
        saveState()
    }
    
    // Получение статистики активных таймеров
    func getActiveTimersInfo() -> (count: Int, ids: [String]) {
        lock.lock()
        defer { lock.unlock() }
        
        let activeTimers = habitTimers.filter { $0.value.isActive }
        return (activeTimers.count, Array(activeTimers.keys))
    }
}
