import Foundation
import SwiftData
import UIKit

@Observable
final class HabitTimerService {
    static let shared = HabitTimerService()
    
    // MARK: - Типы и структуры данных
    
    /// Структура данных для хранения информации о таймере
    private struct TimerData: Codable {
        var startTimestamp: TimeInterval?  // Момент запуска таймера (Unix timestamp)
        var accumulatedSeconds: Int        // Накопленное время в секундах
        var isActive: Bool                 // Флаг активности таймера
    }
    
    /// Ключи для хранения настроек
    private enum Keys {
        static let timerData = "habit.timer.data"
    }
    
    // MARK: - Свойства
    
    /// Словарь с прогрессом для каждого таймера
    private(set) var progressUpdates: [String: Int] = [:]
    
    /// Словарь с данными таймеров
    private var habitTimers: [String: TimerData] = [:]
    
    /// Таймер для регулярного обновления
    private var timerTask: Task<Void, Never>?
    
    /// Защита доступа к данным
    private let lock = NSLock()
    
    /// Время между обновлениями UI (в секундах)
    private let updateInterval: TimeInterval = 1.0
    
    /// Время последнего обновления UI
    private var lastUIUpdateTime: TimeInterval = 0
    
    /// Флаг необходимости обновления UI
    private var needsUIUpdate: Bool = false
    
    // MARK: - Инициализация
    
    private init() {
        loadSavedState()
        startTimerTask()
        setupApplicationLifecycleObservers()
    }
    
    deinit {
        timerTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Настройка таймеров
    
    private func setupApplicationLifecycleObservers() {
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
    
    private func startTimerTask() {
        // Отменяем предыдущую задачу, если она существует
        timerTask?.cancel()
        
        timerTask = Task { @MainActor in
            // Используем единый таймер для всех привычек
            for await _ in AsyncTimerSequence(interval: .milliseconds(500), tolerance: .milliseconds(100)) {
                if Task.isCancelled { break }
                
                updateAllProgress()
                
                // Отправляем уведомление об обновлении UI, только если прошло достаточно времени
                // или если явно указано, что обновление необходимо
                let currentTime = Date().timeIntervalSince1970
                if currentTime - lastUIUpdateTime >= updateInterval || needsUIUpdate {
                    notifyProgressUpdated()
                    lastUIUpdateTime = currentTime
                    needsUIUpdate = false
                }
            }
        }
    }
    
    private func updateAllProgress() {
            var hasLocalChanges = false
            
            withLock {
                let now = Date().timeIntervalSince1970
                
                for (habitId, data) in habitTimers where data.isActive {
                    if let startTime = data.startTimestamp {
                        let elapsedTime = Int(now - startTime)
                        let totalSeconds = data.accumulatedSeconds + elapsedTime
                        
                        if progressUpdates[habitId] != totalSeconds {
                            progressUpdates[habitId] = totalSeconds
                            hasLocalChanges = true
                        }
                    }
                }
            }
            
            if hasLocalChanges {
                Task { @MainActor in
                    self.needsUIUpdate = true
                    // Немедленно отправляем уведомление, если требуется
                    notifyProgressUpdated()
                }
            }
        }

    
    private func notifyProgressUpdated() {
        let progressCopy = withLock {
            return progressUpdates
        }
        
        NotificationCenter.default.post(
            name: .progressUpdated,
            object: self,
            userInfo: ["progressUpdates": progressCopy]
        )
    }
    
    // MARK: - Вспомогательный метод для блокировки
    
    private func withLock<T>(_ action: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try action()
    }
    
    // MARK: - Сохранение и загрузка состояния
    
    private func loadSavedState() {
        guard let savedData = UserDefaults.standard.data(forKey: Keys.timerData) else {
            return
        }
        
        do {
            let decodedData = try JSONDecoder().decode([String: TimerData].self, from: savedData)
            let now = Date().timeIntervalSince1970
            
            withLock {
                for (habitId, data) in decodedData {
                    var updatedData = data
                    
                    // Если таймер активен, учитываем прошедшее время
                    if data.isActive, let startTime = data.startTimestamp {
                        let elapsed = Int(now - startTime)
                        
#if DEBUG
                        print("Таймер \(habitId): восстановлен с учетом \(elapsed) секунд прошедшего времени")
#endif
                        
                        updatedData.accumulatedSeconds += elapsed
                        updatedData.startTimestamp = now // Обновляем timestamp для следующего цикла
                    }
                    
                    habitTimers[habitId] = updatedData
                    progressUpdates[habitId] = updatedData.accumulatedSeconds
                }
            }
        } catch {
            print("Ошибка при загрузке сохраненного состояния таймеров: \(error)")
            
            // В случае ошибки декодирования очищаем сохраненные данные
            UserDefaults.standard.removeObject(forKey: Keys.timerData)
        }
    }
    
    private func saveState(synchronous: Bool = false) {
        lock.lock()
        defer { lock.unlock() }
        
        var dataToSave: [String: TimerData] = [:]
        
        for (habitId, data) in habitTimers {
            var timerData = data
            if data.isActive, let startTime = data.startTimestamp {
                let now = Date().timeIntervalSince1970
                let elapsed = Int(now - startTime)
                timerData.accumulatedSeconds += elapsed
                timerData.startTimestamp = now
            }
            dataToSave[habitId] = timerData
        }
        
        do {
            let encodedData = try JSONEncoder().encode(dataToSave)
            if synchronous {
                // Синхронное сохранение для критических сценариев
                UserDefaults.standard.set(encodedData, forKey: Self.Keys.timerData)
            } else {
                // Асинхронное сохранение для некритичных сценариев
                Task.detached(priority: .utility) {
                    UserDefaults.standard.set(encodedData, forKey: Self.Keys.timerData)
                }
            }
        } catch {
            print("Ошибка кодирования данных таймеров: \(error)")
        }
    }
    
    // MARK: - Обработка жизненного цикла приложения
    
    @objc func handleAppDidEnterBackground() {
        saveState(synchronous: true)
    }
    
    @objc func handleAppWillEnterForeground() {
        updateAllProgress()
        notifyProgressUpdated() // Принудительно обновляем UI
    }
    
    @objc func handleAppWillTerminate() {
        // Отменяем все активные таймеры перед сохранением
        lock.lock()
        let activeTimerIds = habitTimers.filter { $0.value.isActive }.keys
        lock.unlock()
        
        // Останавливаем каждый активный таймер
        for habitId in activeTimerIds {
            stopTimer(for: habitId)
        }
        
        // Теперь сохраняем окончательное состояние
        saveState(synchronous: true)
        timerTask?.cancel()
    }
    
    // MARK: - Управление таймерами
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        var shouldSave = false
        var shouldUpdate = false
        
        withLock {
            if habitTimers[habitId] == nil {
                habitTimers[habitId] = TimerData(
                    startTimestamp: nil,
                    accumulatedSeconds: initialProgress,
                    isActive: false
                )
            }
            
            guard !(habitTimers[habitId]?.isActive ?? false) else {
                return
            }
            
            // Убираем ограничение на количество таймеров
            
            let now = Date().timeIntervalSince1970
            habitTimers[habitId]?.startTimestamp = now
            habitTimers[habitId]?.isActive = true
            
            let progress = habitTimers[habitId]?.accumulatedSeconds ?? 0
            progressUpdates[habitId] = progress
            
            shouldSave = true
            shouldUpdate = true
        }
        
        if shouldUpdate {
            notifyProgressUpdated()
        }
        
        if shouldSave {
            saveState()
        }
    }
    
    func stopTimer(for habitId: String) {
        var shouldSave = false
        var shouldUpdate = false
        
        withLock {
            guard var data = habitTimers[habitId], data.isActive else {
                return
            }
            
            if let startTime = data.startTimestamp {
                let now = Date().timeIntervalSince1970
                let elapsedTime = Int(now - startTime)
                data.accumulatedSeconds += elapsedTime
            }
            
            data.startTimestamp = nil
            data.isActive = false
            
            habitTimers[habitId] = data
            progressUpdates[habitId] = data.accumulatedSeconds
            
            shouldSave = true
            shouldUpdate = true
        }
        
        if shouldUpdate {
            notifyProgressUpdated()
        }
        
        if shouldSave {
            saveState()
        }
    }
    
    func resetTimer(for habitId: String) {
        var wasActive = false
        
        withLock {
            wasActive = habitTimers[habitId]?.isActive ?? false
            
            habitTimers[habitId] = TimerData(
                startTimestamp: wasActive ? Date().timeIntervalSince1970 : nil,
                accumulatedSeconds: 0,
                isActive: wasActive
            )
            
            progressUpdates[habitId] = 0
        }
        
        notifyProgressUpdated()
        saveState()
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        var shouldSave = false
        var shouldUpdate = false
        
        withLock {
            if habitTimers[habitId] == nil {
                habitTimers[habitId] = TimerData(
                    startTimestamp: nil,
                    accumulatedSeconds: 0,
                    isActive: false
                )
            }
            
            let wasActive = habitTimers[habitId]?.isActive ?? false
            var currentSeconds = habitTimers[habitId]?.accumulatedSeconds ?? 0
            
            if wasActive, let startTime = habitTimers[habitId]?.startTimestamp {
                let now = Date().timeIntervalSince1970
                let elapsedTime = Int(now - startTime)
                currentSeconds += elapsedTime
                
                habitTimers[habitId]?.startTimestamp = now
            }
            
            currentSeconds += value
            
            habitTimers[habitId]?.accumulatedSeconds = currentSeconds
            progressUpdates[habitId] = currentSeconds
            
            shouldSave = true
            shouldUpdate = true
        }
        
        if shouldUpdate {
            notifyProgressUpdated()
        }
        
        if shouldSave {
            saveState()
        }
    }
    
    // MARK: - Получение данных
    
    func getCurrentProgress(for habitId: String) -> Int {
        withLock {
            if let data = habitTimers[habitId], data.isActive, let startTime = data.startTimestamp {
                let now = Date().timeIntervalSince1970
                let elapsedTime = Int(now - startTime)
                return data.accumulatedSeconds + elapsedTime
            }
            
            return habitTimers[habitId]?.accumulatedSeconds ?? 0
        }
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        withLock {
            return habitTimers[habitId]?.isActive ?? false
        }
    }
    
    // MARK: - SwiftData интеграция
    
    func persistCompletions(
        for habitId: String,
        in modelContext: ModelContext,
        date: Date = .now,
        retryCount: Int = 0
    ) {
        // Получаем прогресс атомарно
        let currentProgress = getCurrentProgress(for: habitId)
        
        guard currentProgress > 0 else { return }
        
        Task { @MainActor in
            do {
                // Сначала нужно получить все привычки
                let descriptor = FetchDescriptor<Habit>()
                let allHabits = try modelContext.fetch(descriptor)
                
                // Затем находим нужную по UUID (преобразованному из строки)
                guard let uuid = UUID(uuidString: habitId),
                      let habit = allHabits.first(where: { $0.uuid == uuid }) else {
                    return
                }
                
                let existingProgress = habit.progressForDate(date)
                
                // Если прогресс не изменился, нет смысла обновлять
                if currentProgress == existingProgress { return }
                
                try modelContext.transaction {
                    if currentProgress < existingProgress {
                        // Удаляем старые записи
                        let oldCompletions = habit.completions.filter {
                            Calendar.current.isDate($0.date, inSameDayAs: date)
                        }
                        for completion in oldCompletions {
                            modelContext.delete(completion)
                        }
                        
                        // Добавляем новый прогресс
                        if currentProgress > 0 {
                            habit.addProgress(currentProgress, for: date)
                        }
                    } else {
                        // Добавляем разницу
                        habit.addProgress(currentProgress - existingProgress, for: date)
                    }
                }
                
                try modelContext.save()
            } catch {
                print("Ошибка сохранения прогресса: \(error.localizedDescription)")
                
                // Ограничиваем количество повторных попыток
                if retryCount < 3 {
                    try? await Task.sleep(for: .seconds(1))
                    // Неопасный вызов с инкрементом счетчика повторов
                    persistCompletions(for: habitId, in: modelContext, date: date, retryCount: retryCount + 1)
                }
            }
        }
    }
    
    func persistAllCompletionsToSwiftData(modelContext: ModelContext) {
        lock.lock()
        let currentProgressCopy = progressUpdates
        lock.unlock()
        
        // Для данного контекста сохраняем все таймеры с ненулевым прогрессом
        for (habitId, progress) in currentProgressCopy where progress > 0 {
            // Используем существующий метод для сохранения каждого таймера
            persistCompletions(for: habitId, in: modelContext, date: Date())
        }
    }
    
    // MARK: - Вспомогательные методы
    
    func cleanupUnusedTimers() {
        var timersToRemove: [String] = []
        
        withLock {
            timersToRemove = habitTimers.filter {
                !$0.value.isActive && $0.value.accumulatedSeconds == 0
            }.keys.map { $0 }
            
            for id in timersToRemove {
                habitTimers.removeValue(forKey: id)
                progressUpdates.removeValue(forKey: id)
            }
        }
        
        if !timersToRemove.isEmpty {
            saveState()
        }
    }
    
    func getActiveTimersInfo() -> (count: Int, ids: [String]) {
        withLock {
            let activeTimers = habitTimers.filter { $0.value.isActive }
            return (activeTimers.count, Array(activeTimers.keys))
        }
    }
    
    // MARK: - Поток обновлений для асинхронного наблюдения
    
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
                
                // Получаем копию прогресса атомарно
                let progressCopy = withLock {
                    return self.progressUpdates
                }
                
                continuation.yield(progressCopy)
            }
            
            continuation.onTermination = { [weak self] _ in
                NotificationCenter.default.removeObserver(observer)
                
                // Убедимся, что состояние сохранено при завершении потока
                self?.saveState()
            }
        }
    }
    
    var objectWillChangeSequence: AsyncStream<Void> {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: .objectWillChange,
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

// MARK: - Расширения

extension Notification.Name {
    static let progressUpdated = Notification.Name("ProgressUpdated")
    static let objectWillChange = Notification.Name("ObservableObjectWillChange")
}

// MARK: - AsyncTimer для iOS 17+

struct AsyncTimerSequence: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = Void
    
    let interval: Duration
    let tolerance: Duration
    
    func makeAsyncIterator() -> Self {
        self
    }
    
    mutating func next() async -> Void? {
        try? await Task.sleep(for: interval, tolerance: tolerance)
        return Task.isCancelled ? nil : ()
    }
}
