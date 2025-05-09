import Foundation
import SwiftData

@Observable
final class HabitCounterService: ProgressTrackingService {
    // MARK: - Singleton
    
    static let shared = HabitCounterService()
    
    // MARK: - Типы и структуры данных
    
    /// Ключи для хранения настроек
    private enum Keys {
        static let counterData = "habit.counter.data"
    }
    
    // MARK: - Свойства
    
    /// Словарь с прогрессом для каждого счетчика
    private(set) var progressUpdates: [String: Int] = [:]
    
    /// Защита доступа к данным
    private let lock = NSLock()
    
    // MARK: - Инициализация
    
    private init() {
        loadSavedState()
    }
    
    // MARK: - ProgressTrackingService
    
    func getCurrentProgress(for habitId: String) -> Int {
        withLock {
            return progressUpdates[habitId] ?? 0
        }
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        var shouldUpdate = false
        var shouldSave = false
        
        withLock {
            let currentValue = progressUpdates[habitId] ?? 0
            // Не допускаем отрицательных значений
            let newValue = max(0, currentValue + value)
            
            if currentValue != newValue {
                progressUpdates[habitId] = newValue
                shouldUpdate = true
                shouldSave = true
            }
        }
        
        if shouldUpdate {
            notifyProgressUpdated()
        }
        
        if shouldSave {
            saveState()
        }
    }
    
    func resetProgress(for habitId: String) {
        var shouldUpdate = false
        
        withLock {
            if progressUpdates[habitId] != nil && progressUpdates[habitId] != 0 {
                progressUpdates[habitId] = 0
                shouldUpdate = true
            }
        }
        
        if shouldUpdate {
            notifyProgressUpdated()
            saveState()
        }
    }
    
    // Методы для таймеров (заглушки для счетчиков)
    
    func isTimerRunning(for habitId: String) -> Bool {
        return false // Для счетчиков таймеры не используются
    }
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        // Нет операций для счетчиков
    }
    
    func stopTimer(for habitId: String) {
        // Нет операций для счетчиков
    }
    
    // MARK: - SwiftData интеграция
    
    func persistCompletions(for habitId: String, in modelContext: ModelContext, date: Date = .now) {
        let currentProgress = getCurrentProgress(for: habitId)
        
        guard currentProgress > 0 else { return }
        
        Task { @MainActor in
            do {
                // Находим привычку по UUID
                guard let uuid = UUID(uuidString: habitId) else { return }
                
                let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.uuid == uuid })
                let habits = try modelContext.fetch(descriptor)
                
                guard let habit = habits.first else { return }
                
                let existingProgress = habit.progressForDate(date)
                
                // Если прогресс не изменился, нет смысла обновлять
                if currentProgress == existingProgress { return }
                
                // Создаем транзакцию для атомарного обновления
                try modelContext.transaction {
                    // Удаляем старые записи
                    let oldCompletions = habit.completions.filter {
                        Calendar.current.isDate($0.date, inSameDayAs: date)
                    }
                    
                    for completion in oldCompletions {
                        modelContext.delete(completion)
                    }
                    
                    // Добавляем новую запись с полным прогрессом
                    if currentProgress > 0 {
                        let newCompletion = HabitCompletion(date: date, value: currentProgress, habit: habit)
                        habit.completions.append(newCompletion)
                    }
                }
                
                try modelContext.save()
            } catch {
                print("Ошибка сохранения прогресса счетчика: \(error.localizedDescription)")
            }
        }
    }
    
    func persistAllCompletionsToSwiftData(modelContext: ModelContext) {
        let currentProgressCopy = withLock {
            return progressUpdates
        }
        
        for (habitId, progress) in currentProgressCopy where progress > 0 {
            persistCompletions(for: habitId, in: modelContext, date: Date())
        }
    }
    
    // MARK: - Вспомогательные методы
    
    private func loadSavedState() {
        guard let savedData = UserDefaults.standard.data(forKey: Keys.counterData) else {
            return
        }
        
        do {
            let decodedData = try JSONDecoder().decode([String: Int].self, from: savedData)
            
            withLock {
                progressUpdates = decodedData
            }
        } catch {
            print("Ошибка при загрузке сохраненного состояния счетчиков: \(error)")
            UserDefaults.standard.removeObject(forKey: Keys.counterData)
        }
    }
    
    private func saveState() {
        let progressCopy = withLock {
            return progressUpdates
        }
        
        Task.detached(priority: .utility) {
            do {
                let encodedData = try JSONEncoder().encode(progressCopy)
                UserDefaults.standard.set(encodedData, forKey: Self.Keys.counterData)
            } catch {
                print("Ошибка кодирования данных счетчиков: \(error)")
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
    
    private func withLock<T>(_ action: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try action()
    }
    
    // MARK: - AsyncStream для обновлений
    
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
                
                let progressCopy = withLock {
                    return self.progressUpdates
                }
                
                continuation.yield(progressCopy)
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
