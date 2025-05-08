import Foundation
import Combine
import SwiftData

class HabitTimerService: ObservableObject {
    static let shared = HabitTimerService()
    
    // MARK: - Properties
    
    // Структура данных для таймеров
    private struct TimerData {
        var startTimestamp: TimeInterval?    // Момент запуска таймера (Unix timestamp)
        var accumulatedSeconds: Int          // Накопленное время в секундах
        var isActive: Bool                   // Флаг активности таймера
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
        let now = Date().timeIntervalSince1970
        for (habitId, data) in habitTimers where data.isActive {
            if let startTime = data.startTimestamp {
                let elapsedTime = Int(now - startTime)
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
        // Загружаем накопленное время и статус таймеров
        if let savedData = UserDefaults.standard.dictionary(forKey: Keys.timerData) as? [String: [String: Any]] {
            lock.lock()
            for (habitId, data) in savedData {
                let accumulatedSeconds = data["accumulated"] as? Int ?? 0
                let startTimestamp = data["startTime"] as? TimeInterval
                let isActive = data["isActive"] as? Bool ?? false
                
                habitTimers[habitId] = TimerData(
                    startTimestamp: isActive ? Date().timeIntervalSince1970 : startTimestamp,
                    accumulatedSeconds: accumulatedSeconds,
                    isActive: isActive
                )
                
                // Обновляем прогресс сразу для UI
                progressUpdates[habitId] = accumulatedSeconds
            }
            lock.unlock()
        }
    }
    
    private func saveState() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            var dataToSave: [String: [String: Any]] = [:]
            
            self.lock.lock()
            for (habitId, data) in self.habitTimers {
                var timerData: [String: Any] = [:]
                
                // Если таймер активен, сначала обновим накопленное время
                if data.isActive, let startTime = data.startTimestamp {
                    let now = Date().timeIntervalSince1970
                    let elapsed = Int(now - startTime)
                    let totalAccumulated = data.accumulatedSeconds + elapsed
                    
                    timerData["accumulated"] = totalAccumulated
                    timerData["startTime"] = now // Обновляем время старта
                } else {
                    timerData["accumulated"] = data.accumulatedSeconds
                    timerData["startTime"] = data.startTimestamp
                }
                
                timerData["isActive"] = data.isActive
                dataToSave[habitId] = timerData
            }
            self.lock.unlock()
            
            UserDefaults.standard.set(dataToSave, forKey: HabitTimerService.Keys.timerData)
        }
    }
    
    // MARK: - Обработка состояния приложения
    
    func handleAppDidEnterBackground() {
        saveState() // Сохраняем текущее состояние
    }
    
    func handleAppWillEnterForeground() {
        // При возвращении в приложение не нужно специально обрабатывать,
        // так как мы будем вычислять прошедшее время по timestamp
        // Просто обновляем прогресс, чтобы отразить изменения
        updateAllProgress()
    }
    
    // MARK: - Управление таймерами
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        lock.lock()
        
        // Создаем запись для привычки, если нет
        if habitTimers[habitId] == nil {
            habitTimers[habitId] = TimerData(
                startTimestamp: nil,
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
        let now = Date().timeIntervalSince1970
        habitTimers[habitId]?.startTimestamp = now
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
        if let startTime = data.startTimestamp {
            let now = Date().timeIntervalSince1970
            let elapsedTime = Int(now - startTime)
            data.accumulatedSeconds += elapsedTime
        }
        
        // Деактивируем таймер
        data.startTimestamp = nil
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
            startTimestamp: wasActive ? Date().timeIntervalSince1970 : nil,
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
                startTimestamp: nil,
                accumulatedSeconds: 0,
                isActive: false
            )
        }
        
        // Сохраняем состояние активности
        let wasActive = habitTimers[habitId]?.isActive ?? false
        var currentSeconds = habitTimers[habitId]?.accumulatedSeconds ?? 0
        
        // Если таймер активен, добавляем накопленное время
        if wasActive, let startTime = habitTimers[habitId]?.startTimestamp {
            let now = Date().timeIntervalSince1970
            let elapsedTime = Int(now - startTime)
            currentSeconds += elapsedTime
            
            // Обновляем время начала
            habitTimers[habitId]?.startTimestamp = now
        }
        
        // Добавляем новое значение
        currentSeconds += value
        
        // Обновляем состояние
        habitTimers[habitId]?.accumulatedSeconds = currentSeconds
        
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
        
        // Если таймер активен, вычисляем текущее время
        if let data = habitTimers[habitId], data.isActive, let startTime = data.startTimestamp {
            let now = Date().timeIntervalSince1970
            let elapsedTime = Int(now - startTime)
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
                    // Если текущий прогресс меньше существующего, удаляем записи и создаем новую
                    if currentProgress < existingProgress {
                        let existingCompletions = habit.completions.filter {
                            Calendar.current.isDate($0.date, inSameDayAs: date)
                        }
                        
                        for completion in existingCompletions {
                            modelContext.delete(completion)
                        }
                        
                        // Если прогресс > 0, добавляем новую запись
                        if currentProgress > 0 {
                            habit.addProgress(currentProgress, for: date)
                        }
                    } else {
                        // Если прогресс больше, просто добавляем разницу
                        habit.addProgress(currentProgress - existingProgress, for: date)
                    }
                    
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
