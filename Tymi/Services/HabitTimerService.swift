import Foundation
import Combine
import UIKit
import OSLog
import SwiftData

class HabitTimerService: ObservableObject {
    static let shared = HabitTimerService()
    
    private let logger = Logger(subsystem: "com.tymi", category: "HabitTimerService")
    private let timerInterval: TimeInterval = 1.0
    
    private var timers: [String: Timer] = [:]
    private var startTimes: [String: Date] = [:]
    private var accumulatedTimes: [String: TimeInterval] = [:]
    private var backgroundTaskIdentifiers: [String: UIBackgroundTaskIdentifier] = [:]
    
    // Оптимизация сохранения
    private var needsSave = false
    private var saveWorkItem: DispatchWorkItem?
    
    @Published private(set) var progressUpdates: [String: Int] = [:]
    
    // Ключи для UserDefaults
    private enum UserDefaultsKeys {
        static let accumulatedTimes = "habitTimerAccumulatedTimes"
        static let activeTimers = "habitTimerActiveTimers"
    }
    
    private init() {
        setupNotifications()
        loadSavedState()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    private func loadSavedState() {
        logger.debug("Загрузка сохраненного состояния таймеров")
        
        // Загрузка накопленного времени
        if let savedAccumulatedTimes = UserDefaults.standard.dictionary(forKey: UserDefaultsKeys.accumulatedTimes) as? [String: TimeInterval] {
            accumulatedTimes = savedAccumulatedTimes
            for (habitId, time) in savedAccumulatedTimes {
                progressUpdates[habitId] = Int(time)
            }
            logger.debug("Загружено накопленное время для \(savedAccumulatedTimes.count) таймеров")
        } else {
            logger.error("Не удалось загрузить данные о накопленном времени таймеров")
        }
        
        // Восстановление активных таймеров
        if let activeTimerIds = UserDefaults.standard.array(forKey: UserDefaultsKeys.activeTimers) as? [String] {
            for habitId in activeTimerIds {
                if let accumulatedTime = accumulatedTimes[habitId] {
                    startTimer(for: habitId, initialProgress: Int(accumulatedTime))
                    logger.debug("Восстановлен таймер для привычки \(habitId)")
                }
            }
        } else {
            logger.error("Не удалось загрузить данные об активных таймерах")
        }
    }
    
    private func saveTimerState() {
        logger.debug("Сохранение состояния таймеров")
        
        // Сохранение накопленного времени
        UserDefaults.standard.set(accumulatedTimes, forKey: UserDefaultsKeys.accumulatedTimes)
        
        // Сохранение активных таймеров
        let activeTimerIds = Array(timers.keys)
        UserDefaults.standard.set(activeTimerIds, forKey: UserDefaultsKeys.activeTimers)
        
        UserDefaults.standard.synchronize()
        logger.debug("Состояние таймеров сохранено")
    }
    
    private func scheduleTimerStateSave() {
        needsSave = true
        
        // Отменяем предыдущую запланированную задачу
        saveWorkItem?.cancel()
        
        // Создаем новую задачу
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveTimerStateIfNeeded()
        }
        
        // Сохраняем с задержкой
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func saveTimerStateIfNeeded() {
        guard needsSave else { return }
        saveTimerState()
        needsSave = false
    }
    
    // MARK: - Notification Handlers
    
    @objc public func handleAppDidEnterBackground() {
        logger.debug("Приложение перешло в фоновый режим")
        for (habitId, _) in timers {
            if let startTime = startTimes[habitId] {
                let elapsedTime = Date().timeIntervalSince(startTime)
                accumulatedTimes[habitId] = (accumulatedTimes[habitId] ?? 0) + elapsedTime
                startTimes[habitId] = nil
            }
        }
        saveTimerState()
    }
    
    @objc public func handleAppWillEnterForeground() {
        logger.debug("Приложение вернулось в активный режим")
        for (habitId, _) in timers {
            if let accumulatedTime = accumulatedTimes[habitId] {
                startTimer(for: habitId, initialProgress: Int(accumulatedTime))
            }
        }
        saveTimerState()
    }
    
    @objc private func handleAppWillTerminate() {
        logger.debug("Приложение будет закрыто")
        saveTimerState()
    }
    
    // MARK: - Timer Management
    
    /// Запускает таймер для указанной привычки
    /// - Parameters:
    ///   - habitId: Идентификатор привычки
    ///   - initialProgress: Начальное значение прогресса
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        logger.debug("Запуск таймера для привычки \(habitId)")
        stopTimer(for: habitId)
        
        startTimes[habitId] = Date()
        accumulatedTimes[habitId] = TimeInterval(initialProgress)
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateProgress(for: habitId)
        }
        
        RunLoop.main.add(timer, forMode: .common)
        timers[habitId] = timer
        
        updateProgress(for: habitId)
        scheduleTimerStateSave()
    }
    
    /// Останавливает таймер для указанной привычки
    /// - Parameter habitId: Идентификатор привычки
    func stopTimer(for habitId: String) {
        logger.debug("Остановка таймера для привычки \(habitId)")
        
        updateProgress(for: habitId)
        
        timers[habitId]?.invalidate()
        timers[habitId] = nil
        
        if let startTime = startTimes[habitId] {
            let elapsedTime = Date().timeIntervalSince(startTime)
            accumulatedTimes[habitId] = (accumulatedTimes[habitId] ?? 0) + elapsedTime
        }
        
        startTimes[habitId] = nil
        
        if let backgroundTask = backgroundTaskIdentifiers[habitId] {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTaskIdentifiers[habitId] = nil
        }
        
        scheduleTimerStateSave()
    }
    
    /// Сбрасывает таймер для указанной привычки
    /// - Parameter habitId: Идентификатор привычки
    func resetTimer(for habitId: String) {
        logger.debug("Сброс таймера для привычки \(habitId)")
        stopTimer(for: habitId)
        accumulatedTimes[habitId] = 0
        progressUpdates[habitId] = 0
        scheduleTimerStateSave()
    }
    
    /// Добавляет указанное значение к прогрессу привычки
    /// - Parameters:
    ///   - value: Значение для добавления
    ///   - habitId: Идентификатор привычки
    func addProgress(_ value: Int, for habitId: String) {
        logger.debug("Добавление прогресса \(value) для привычки \(habitId)")
        stopTimer(for: habitId)
        
        let currentProgress = getCurrentProgress(for: habitId)
        let newProgress = max(0, currentProgress + value)
        
        accumulatedTimes[habitId] = TimeInterval(newProgress)
        progressUpdates[habitId] = newProgress
        scheduleTimerStateSave()
    }
    
    // MARK: - Getters
    
    /// Возвращает текущий прогресс для указанной привычки
    /// - Parameter habitId: Идентификатор привычки
    /// - Returns: Текущее значение прогресса
    func getCurrentProgress(for habitId: String) -> Int {
        return progressUpdates[habitId] ?? 0
    }
    
    /// Проверяет, запущен ли таймер для указанной привычки
    /// - Parameter habitId: Идентификатор привычки
    /// - Returns: true, если таймер запущен
    func isTimerRunning(for habitId: String) -> Bool {
        return timers[habitId] != nil
    }
    
    /// Проверяет, был ли запущен таймер для указанной привычки
    /// - Parameter habitId: Идентификатор привычки
    /// - Returns: true, если таймер был запущен
    func wasTimerRunning(for habitId: String) -> Bool {
        return startTimes[habitId] != nil
    }
    
    /// Восстанавливает состояние таймера для указанной привычки
    /// - Parameter habitId: Идентификатор привычки
    func restoreTimerState(for habitId: String) {
        if startTimes[habitId] != nil {
            startTimer(for: habitId, initialProgress: progressUpdates[habitId] ?? 0)
        }
    }
    
    private func updateProgress(for habitId: String) {
        var totalTime: TimeInterval = accumulatedTimes[habitId] ?? 0
        
        if let startTime = startTimes[habitId] {
            totalTime += Date().timeIntervalSince(startTime)
        }
        
        let progress = Int(totalTime)
        progressUpdates[habitId] = progress
    }
    
    // MARK: - SwiftData Integration
    
    /// Сохраняет прогресс в базу данных SwiftData
    /// - Parameters:
    ///   - habitId: Идентификатор привычки
    ///   - modelContext: Контекст модели SwiftData
    ///   - date: Дата для сохранения прогресса
    func persistCompletions(for habitId: String, in modelContext: ModelContext, date: Date = .now) {
        guard let currentProgress = progressUpdates[habitId], currentProgress > 0,
              let habit = fetchHabit(with: habitId, in: modelContext) else { return }
        
        let existingProgress = habit.progressForDate(date)
        
        if currentProgress != existingProgress {
            habit.addProgress(currentProgress - existingProgress, for: date)
        }
    }
    
    private func fetchHabit(with id: String, in context: ModelContext) -> Habit? {
        let descriptor = FetchDescriptor<Habit>()
        do {
            let habits = try context.fetch(descriptor)
            return habits.first { String(describing: $0.persistentModelID) == id }
        } catch {
            print("Ошибка при поиске привычки: \(error.localizedDescription)")
            return nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Останавливаем все таймеры при деинициализации
        for (habitId, _) in timers {
            stopTimer(for: habitId)
        }
    }
} 
