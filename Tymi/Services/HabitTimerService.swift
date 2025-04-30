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
    private var progress: [String: Int] = [:]
    private var startTimes: [String: Date] = [:]
    private var backgroundTaskIdentifiers: [String: UIBackgroundTaskIdentifier] = [:]
    
    // Оптимизация сохранения
    private var needsSave = false
    private var saveWorkItem: DispatchWorkItem?
    
    @Published private(set) var progressUpdates: [String: Int] = [:]
    
    // Ключи для UserDefaults
    private enum UserDefaultsKeys {
        static let progress = "habitTimerProgress"
        static let startTimes = "habitTimerStartTimes"
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
    
    // MARK: - State Management
    
    private func loadSavedState() {
        logger.debug("Загрузка сохраненного состояния таймеров")
        
        // Загрузка прогресса
        if let savedProgress = UserDefaults.standard.dictionary(forKey: UserDefaultsKeys.progress) as? [String: Int] {
            progress = savedProgress
            progressUpdates = savedProgress
            logger.debug("Загружен прогресс для \(savedProgress.count) таймеров")
        } else {
            logger.error("Не удалось загрузить данные о прогрессе таймеров")
        }
        
        // Загрузка времени старта
        if let savedStartTimes = UserDefaults.standard.dictionary(forKey: UserDefaultsKeys.startTimes) as? [String: TimeInterval] {
            startTimes = savedStartTimes.mapValues { Date(timeIntervalSince1970: $0) }
            logger.debug("Загружено время старта для \(savedStartTimes.count) таймеров")
        } else {
            logger.error("Не удалось загрузить данные о времени старта таймеров")
        }
        
        // Восстановление активных таймеров
        if let activeTimerIds = UserDefaults.standard.array(forKey: UserDefaultsKeys.activeTimers) as? [String] {
            for habitId in activeTimerIds {
                if let savedProgress = progress[habitId] {
                    startTimer(for: habitId, initialProgress: savedProgress)
                    logger.debug("Восстановлен таймер для привычки \(habitId)")
                }
            }
        } else {
            logger.error("Не удалось загрузить данные об активных таймерах")
        }
    }
    
    private func saveTimerState() {
        logger.debug("Сохранение состояния таймеров")
        
        // Сохранение прогресса
        UserDefaults.standard.set(progress, forKey: UserDefaultsKeys.progress)
        
        // Сохранение времени старта
        let startTimesToSave = startTimes.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(startTimesToSave, forKey: UserDefaultsKeys.startTimes)
        
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
    
    @objc private func handleAppDidEnterBackground() {
        logger.debug("Приложение перешло в фоновый режим")
        for (habitId, _) in timers {
            if let startTime = startTimes[habitId] {
                let elapsedTime = Int(Date().timeIntervalSince(startTime))
                let newProgress = (progress[habitId] ?? 0) + elapsedTime
                progress[habitId] = newProgress
                progressUpdates[habitId] = newProgress
                
                let backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                    self?.stopTimer(for: habitId)
                }
                backgroundTaskIdentifiers[habitId] = backgroundTask
            }
        }
        saveTimerState()
    }
    
    @objc private func handleAppWillEnterForeground() {
        logger.debug("Приложение вернулось в активный режим")
        for (habitId, _) in timers {
            if let backgroundTask = backgroundTaskIdentifiers[habitId] {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTaskIdentifiers[habitId] = nil
            }
            
            if let startTime = startTimes[habitId] {
                let elapsedTime = Int(Date().timeIntervalSince(startTime))
                let newProgress = (progress[habitId] ?? 0) + elapsedTime
                progress[habitId] = newProgress
                progressUpdates[habitId] = newProgress
                startTimes[habitId] = Date()
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
        
        progress[habitId] = initialProgress
        progressUpdates[habitId] = initialProgress
        startTimes[habitId] = Date()
        
        let timer = Timer(timeInterval: timerInterval, repeats: true) { [weak self] _ in
            guard let self = self,
                  let startTime = self.startTimes[habitId] else { return }
            
            let elapsedTime = Int(Date().timeIntervalSince(startTime))
            let newProgress = initialProgress + elapsedTime
            
            self.progress[habitId] = newProgress
            self.progressUpdates[habitId] = newProgress
        }
        
        RunLoop.main.add(timer, forMode: .common)
        timers[habitId] = timer
        scheduleTimerStateSave()
    }
    
    /// Останавливает таймер для указанной привычки
    /// - Parameter habitId: Идентификатор привычки
    func stopTimer(for habitId: String) {
        logger.debug("Остановка таймера для привычки \(habitId)")
        
        // Обновляем прогресс перед остановкой
        if let startTime = startTimes[habitId] {
            let elapsedTime = Int(Date().timeIntervalSince(startTime))
            let newProgress = (progress[habitId] ?? 0) + elapsedTime
            progress[habitId] = newProgress
            progressUpdates[habitId] = newProgress
        }
        
        timers[habitId]?.invalidate()
        timers[habitId] = nil
        
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
        progress[habitId] = 0
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
        
        // Защита от отрицательных значений
        let currentProgress = getCurrentProgress(for: habitId)
        let validValue = value < 0 ? max(value, -currentProgress) : value
        
        let newProgress = currentProgress + validValue
        progress[habitId] = newProgress
        progressUpdates[habitId] = newProgress
        scheduleTimerStateSave()
    }
    
    // MARK: - Getters
    
    /// Возвращает текущий прогресс для указанной привычки
    /// - Parameter habitId: Идентификатор привычки
    /// - Returns: Текущее значение прогресса
    func getCurrentProgress(for habitId: String) -> Int {
        return progress[habitId] ?? 0
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
            startTimer(for: habitId, initialProgress: progress[habitId] ?? 0)
        }
    }
    
    // MARK: - SwiftData Integration
    
    /// Сохраняет прогресс в базу данных SwiftData
    /// - Parameters:
    ///   - habitId: Идентификатор привычки
    ///   - modelContext: Контекст модели SwiftData
    ///   - date: Дата для сохранения прогресса
    func persistCompletions(for habitId: String, in modelContext: ModelContext, date: Date = .now) {
        guard let currentProgress = progress[habitId], currentProgress > 0,
              let habit = fetchHabit(with: habitId, in: modelContext) else { return }
        
        // Получаем существующий прогресс
        let existingProgress = habit.progressForDate(date)
        
        // Если прогресс изменился, создаем новую запись
        if currentProgress != existingProgress {
            habit.addProgress(currentProgress - existingProgress, for: date)
            logger.debug("Сохранен прогресс \(currentProgress) для привычки \(habitId)")
        }
    }
    
    private func fetchHabit(with id: String, in context: ModelContext) -> Habit? {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { 
                String(describing: $0.persistentModelID) == id 
            }
        )
        
        return try? context.fetch(descriptor).first
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 